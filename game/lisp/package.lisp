;;;; package.lisp — RAVEN EDGE, a Ninja-Gaiden-style action game built on the engine (engine/).
;;;; Everything under game/ is in this package; it sees the engine's exported API directly.
;;;; Also here: CLOG, the dev combat log every file writes to.
(defpackage :raven
  (:use :cl :engine))
(in-package :raven)

(defvar *combat-log* nil
  "Dev logging: state changes, hits, damage, 2 s stats lines, F3 overlay. Off in release; the first
Module._debug_cmd call turns it on (the test scripts and docs rely on these lines).")

(defmacro clog (fmt &rest args)
  "Combat log line \"[tick] ...\" (only while *COMBAT-LOG* is on; the arguments aren't evaluated otherwise)."
  `(when *combat-log* (log-msg ,(concatenate 'string "[~5d] " fmt) *tick* ,@args)))
