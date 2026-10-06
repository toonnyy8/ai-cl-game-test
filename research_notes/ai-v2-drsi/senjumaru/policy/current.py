"""Adaptive portfolio policy -- the scaffold the policy-development agent edits.

Prefix signals : branch anchor, parent->child gain, trajectory shape,
                 failure recoverability, remaining depth, cross-branch rank.
Batch rule     : one dynamic portfolio per round -- exploitation (strong
                 refinements) + exploration (new roots / underexplored
                 branches) + at most one recovery (a repairable failure).
Beta schedule  : one _schedule(beta) dict drives every threshold. Beta is
                 FIXED inside an episode; it is swept during offline
                 evaluation and baked in once per live cycle.
Safeguards     : a repairable failure never erases the branch's successful
                 anchor; zero-valid is never automatic closure; stop only
                 after considering the whole revealed portfolio; never emit a
                 singleton batch just because one candidate is clearly best.
"""

from __future__ import annotations

from typing import Dict, List, Optional

from policy_api import (
    GridPlan,
    GridPlanningContext,
    LLMDesignedMethod,
    Observation,
    SimResult,
    _budget_done,
    _record_curve,
    branch_anchor,
    branch_failed_hard,
    branch_trajectory,
    finalize_result,
    probe_succeeded,
    stagnating,
)

NAME = "OptimalPolicy"


class OptimalPolicy(LLMDesignedMethod):
    def __init__(self, config=None):
        super().__init__(config)
        self.beta = float(self.config.get("beta", 0.6))

    # -- decision loop -----------------------------------------------------
    def solve(self, question, budget: Optional[int] = None) -> SimResult:
        question.reset()
        res, closed = SimResult(), set()
        sched = self._schedule(self.beta)

        while not _budget_done(question, budget):
            prefix = question.observed()
            self._update_closed(closed, prefix, question, sched)
            batch = self._select_batch(prefix, question, closed, sched)
            if not batch:
                break
            question.probe_batch(batch, on_reveal=lambda _o: _record_curve(res, question))

        return finalize_result(question, res)

    # -- closing -----------------------------------------------------------
    def _update_closed(self, closed, prefix, question, sched) -> None:
        for b in question.opened_branches():
            if b in closed:
                # a later success reopens a branch closed on an earlier failure
                traj = branch_trajectory(prefix, b)
                if traj and probe_succeeded(traj[-1]):
                    closed.discard(b)
                continue
            if branch_failed_hard(prefix, b):
                closed.add(b)
                continue
            if stagnating(prefix, b, window=int(sched["stagnation_window"])):
                anchor = branch_anchor(prefix, b)
                if anchor is not None and anchor <= question.baseline_score:
                    closed.add(b)

    # -- ranking -----------------------------------------------------------
    def _priority(self, prefix: Dict[str, Observation], cid: str, question, sched) -> float:
        m = question.meta(cid)
        if m.attempt == 0:
            # a fresh direction: worth more when few branches have paid off
            anchors = [
                a
                for a in (branch_anchor(prefix, b) for b in question.opened_branches())
                if a is not None
            ]
            best = max(anchors) if anchors else question.baseline_score
            scarcity = 1.0 if not anchors else 0.5
            return 1.0 * sched["explore_slots"] * scarcity + 0.0 * best

        traj = branch_trajectory(prefix, m.branch)
        anchor = branch_anchor(prefix, m.branch)
        base = question.baseline_score
        score = 0.0
        if anchor is not None:
            score += 2.0 * _rel(anchor, base)
        gains = [
            o.delta_vs_parent for o in traj if o.delta_vs_parent is not None
        ]
        if gains:
            score += 1.5 * max(0.0, gains[-1]) / (abs(base) + 1e-9)
        remaining = question.refine_count - m.attempt + 1
        score += 0.2 * sched["max_depth_frac"] * remaining
        if traj and not probe_succeeded(traj[-1]):
            score *= 0.6  # recovery attempt: eligible, but not ahead of winners
        return score

    def _select_batch(self, prefix, question, closed, sched) -> List[str]:
        legal = question.legal_actions()
        if not legal:
            return []
        base = question.baseline_score
        anchors = {b: branch_anchor(prefix, b) for b in question.opened_branches()}
        live = [a for a in anchors.values() if a is not None]
        best_a = max(live) if live else base
        # beta controls how far below the leader a branch may sit and survive:
        # beta=0 keeps only the leader, beta=1 keeps everything above baseline.
        cutoff = best_a - sched["keep_frac"] * max(0.0, best_a - base)

        roots, exploit, recover = [], [], []
        for c in legal:
            m = question.meta(c)
            if m.attempt == 0:
                roots.append(c)
                continue
            if m.branch in closed:
                continue
            traj = branch_trajectory(prefix, m.branch)
            a = anchors.get(m.branch)
            failed_last = bool(traj) and not probe_succeeded(traj[-1])
            if failed_last:
                # a repairable failure stays eligible; its historical anchor stands
                if sched["allow_recovery"] and (a is None or a >= cutoff):
                    recover.append(c)
                continue
            if a is not None and a < cutoff:
                continue  # reserved, not closed: a later round may reopen it
            exploit.append(c)

        key = lambda c: -self._priority(prefix, c, question, sched)
        exploit.sort(key=key)
        recover.sort(key=key)
        roots.sort(key=key)

        # explore less once a direction is clearly paying off, more when not
        if roots and (not live or best_a <= base):
            n_explore = min(len(roots), question.max_parallelism)
        else:
            n_explore = min(len(roots), int(round(sched["explore_slots"])) - 1)
        n_explore = max(0, n_explore)

        W = question.max_parallelism
        batch: List[str] = []
        batch += roots[:n_explore]
        if recover and len(batch) < W:
            batch.append(recover[0])          # at most one recovery per round
        for c in exploit:                     # exploitation fills the rest
            if len(batch) >= W:
                break
            batch.append(c)
        for c in exploit + roots + recover:   # never leave a worker idle
            if len(batch) >= W:
                break
            if c not in batch:
                batch.append(c)
        return batch[:W]

    # -- grid planning (runs BEFORE the next live round) --------------------
    def plan_grid(self, context: GridPlanningContext) -> GridPlan:
        hist = [h for h in context.history if h.get("best") is not None]
        W = min(context.fallback_branch_count, context.hard_max_branch_count)
        R = min(context.fallback_refine_count, context.hard_max_refine_count)
        if len(hist) < 2:
            return GridPlan(W, R, "insufficient history: conservative bootstrap grid")

        last, prev = hist[-1], hist[-2]
        improving = last["best"] > prev["best"]
        deep_gains = last.get("best_attempt_depth", 0) >= 0.6 * max(1, last.get("refine_count", R))

        if improving and deep_gains:
            R = min(R + 1, context.hard_max_refine_count)
            why = "late-arriving gains on few directions: deepen"
        elif improving:
            why = "still improving at current shape: hold"
        elif deep_gains:
            W = min(W + 1, context.hard_max_branch_count)
            why = "plateau with depth already paying off: widen slightly"
        else:
            W = min(W + 1, context.hard_max_branch_count)
            R = max(1, R - 1)
            why = "plateau with shallow gains: trade depth for width"
        return GridPlan(branch_count=W, refine_count=R, reason=why)


def _rel(x: float, base: float) -> float:
    return (x - base) / (abs(base) + 1e-9)
