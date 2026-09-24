;;;; audio-demo.lisp — keyboard sound board for the engine mixer and the game's sound bank.
;;;; ./build.sh audio-demo game/lisp/package.lisp game/lisp/sounds.lisp tests/audio-demo.lisp
;;;; Keys: 1-0 Q W E T Y U I O P A S D F G = sounds, M music, R rain, Z positional clang.
(in-package :raven)   ; the game's sound bank (game/lisp/sounds.lisp)

(setf *audio-debug* t)                  ; the engine's startup logs per-sound stats
(defparameter *ad-keys* "1234567890QWETYUIOPASDFG")
(defparameter *ad-sounds*
  '(:slash-light :slash-heavy :hit-flesh :hit-heavy :clang :parry :dodge :jump :land :footstep
    :kunai-throw :kunai-hit :enemy-death :obliterate :raven-burst :player-hurt :brute-slam :warn
    :boss-roar :ui-move :ui-select :wave-start :victory :game-over))
(defvar *ad-frame* 0)
(defvar *ad-rain* -1)

(defun ad-key (ch)
  (case ch
    (#\M (if (music-playing-p) (music-stop) (music-play)))
    (#\R (if (< *ad-rain* 0) (setf *ad-rain* (start-loop :rain)) (progn (stop-loop *ad-rain*) (setf *ad-rain* -1))))
    (#\Z (play-sfx-at :clang (* 10 (sin (* 0.05 *ad-frame*))) 0.0 -5.0 0.0 0.0 0.0))
    (t (let ((i (position ch *ad-keys*)))
         (when i
           (log-msg "key ~a -> ~a voice ~d" ch (nth i *ad-sounds*) (play-sfx (nth i *ad-sounds*)))))))
  (log-msg "key ~a: active voices ~d music ~a" ch (audio-stats) (music-playing-p)))

(defun ad-frame (dt)
  (declare (ignore dt))
  (loop for ch across (concatenate 'string *ad-keys* "MRZ")
        when (key-pressed (intern (string ch) :keyword)) do (ad-key ch))
  (incf *ad-frame*)
  (when (zerop (mod *ad-frame* 60))
    (multiple-value-bind (voices frames peak ctx) (audio-stats)
      (log-msg "audio: voices ~d  frames-mixed ~d  peak ~,3f  ctx ~[none~;suspended~;running~]"
               voices frames peak ctx))))

(run-game :title "audio demo" :frame #'ad-frame
          :start (lambda () (log-msg "audio-demo: ~d sounds ready" (length *ad-sounds*))))
