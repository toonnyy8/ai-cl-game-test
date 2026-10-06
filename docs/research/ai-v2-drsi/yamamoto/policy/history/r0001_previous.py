"""Baseline: fixed parallel refinement.

Opens every branch, then refines all open branches round-robin until the grid
is exhausted. No pruning, no stopping, no prioritisation -- this is the
parallel-refine floor that Dream-RSI's improved policies must beat, and it is
also the shared initialisation for round 1 of both arms of the comparison.

Its beta knob is deliberately weak (it only caps depth), so its sweep is close
to degenerate. That is expected for the floor.
"""

from __future__ import annotations

from typing import Optional

from policy_api import (
    GridPlan,
    GridPlanningContext,
    LLMDesignedMethod,
    SimResult,
    _budget_done,
    _record_curve,
    finalize_result,
)

NAME = "OptimalPolicy"


class OptimalPolicy(LLMDesignedMethod):
    def __init__(self, config=None):
        super().__init__(config)
        self.beta = float(self.config.get("beta", 1.0))

    def solve(self, question, budget: Optional[int] = None) -> SimResult:
        question.reset()
        res = SimResult()
        sched = self._schedule(self.beta)
        max_depth = max(1, int(round(sched["max_depth_frac"] * question.refine_count)))

        while not _budget_done(question, budget):
            roots = question.legal_roots()
            frontiers = [
                c for c in question.frontiers() if question.meta(c).attempt <= max_depth
            ]
            batch = (roots + frontiers)[: question.max_parallelism]
            if not batch:
                break
            question.probe_batch(batch, on_reveal=lambda _o: _record_curve(res, question))

        return finalize_result(question, res)

    def plan_grid(self, context: GridPlanningContext) -> GridPlan:
        return GridPlan(
            branch_count=min(context.fallback_branch_count, context.hard_max_branch_count),
            refine_count=min(context.fallback_refine_count, context.hard_max_refine_count),
            reason="fixed parallel-refine baseline: grid never adapts",
        )
