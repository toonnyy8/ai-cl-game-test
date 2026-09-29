;;;; One sim-gate process (tools/simgate.py): load the native SOUL DUEL (tools/simgate/build.lisp), start it as the page
;;;; would (every startup step, no audio device), queue the debug commands, then run 1/60 s frames (ENGINE::%FRAME, the
;;;; real frame: flow, gate, turbo steps, camera, HUD; the scene is never drawn in turbo) until the seed gate has printed
;;;; its summary, or a single match (e.g. 2102 3007) has ended. Output = the page's console: "duel gate row ..." and
;;;; "duel gate A B: ..." lines among the rest.
;;;; Usage: ecl-host --norc --load tools/simgate/run.lisp -- <duel.fas> <cmd>...   e.g. 30000 31110 2126
(defparameter cl-user::*sg-args* (cdr (member "--" ext:*command-args* :test #'string=)))
(load (first cl-user::*sg-args*) :verbose nil)
(in-package :duel)
(loop for r = (engine::%init-step) until (eql r 0) when (eql r 2) do (ext:quit 2))
(dolist (c (rest cl-user::*sg-args*)) (engine::simgate-cmd (parse-integer c)))
(engine::%frame)                                        ; the commands run at this frame's start
;; ponytail: 2e6 frames = 240M turbo steps, far past any gate; a hung sim exits 4 instead of spinning forever
(unless (loop repeat 2000000
              do (unless (engine::%frame) (ext:quit 3))
              thereis (and (null *gate*) (not *gate-busy*) (null *gate-results*) (not (battle-p))))
  (ext:quit 4))
(finish-output)
(ext:quit 0)
