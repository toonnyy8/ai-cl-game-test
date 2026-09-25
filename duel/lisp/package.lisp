;;;; package.lisp — SOUL DUEL, a 1v1 arena fighter (a non-commercial BLEACH: Rebirth of Souls fan
;;;; study) built on the engine (engine/). Everything under duel/ is in this package; it sees the
;;;; engine's exported API directly. Contract: the design doc's §12 lists the files in MANIFEST order.
(defpackage :duel
  (:use :cl :engine))
(in-package :duel)
