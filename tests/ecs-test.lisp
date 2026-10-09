;;;; ecs-test.lisp — checks engine/lisp/ecs.lisp on the host (no browser, no build):
;;;;   $ECL_HOST --norc --load tests/ecs-test.lisp
(defpackage :engine (:use :cl))
(load (merge-pathnames "../engine/lisp/ecs.lisp" *load-truename*))
(in-package :engine)

(defcomponent pos "A test component." (x 0 :type fixnum))
(defcomponent tag)

(let* ((a (spawn-entity (make-pos :x 1) (make-tag)))
       (b (spawn-entity (make-pos :x 2)))
       (seen nil))
  (assert (and (entity-alive-p a) (= 1 (pos-x (pos a))) (tag a) (null (tag b))))
  (do-entities (e (p pos) tag) (push (pos-x p) seen))
  (assert (equal seen '(1)))
  (setf seen nil)
  (do-entities (e pos) (push e seen))
  (assert (equal seen (list b a)))                        ; slot order
  (remove-component a 'tag)
  (assert (null (tag a)))
  (destroy-entity a)
  (assert (and (not (entity-alive-p a)) (null (pos a))))
  (let ((c (spawn-entity (make-pos :x 3))))                ; reuses a's slot, new generation
    (assert (and (= (handle-slot c) (handle-slot a)) (/= c a) (null (pos a)) (= 3 (pos-x (pos c))))))
  (assert (not (entity-alive-p nil)))
  (emit :hit 1 2) (emit :died 3)
  (assert (equal (take-events) '((:hit 1 2) (:died 3))))
  (assert (null (take-events)))
  (emit :hit 1 2) (emit :died 3 4) (emit :idle) (emit :other 9)         ; DO-EVENTS: oldest first, one clause per kind
  (let ((out nil))
    (do-events (kind)
      (:hit (att def) (push (list kind att def) out))                    ; a lambda-list destructures the data
      (:died all (push (cons kind all) out))                             ; a symbol gets the whole data list
      (:idle () (push kind out))
      (t (push (list :else kind) out)))
    (assert (equal (nreverse out) '((:hit 1 2) (:died 3 4) :idle (:else :other))))
    (assert (null (take-events))))
  (clear-entities)
  (assert (= *top* 0))
  (format t "ecs-test: ALL PASS~%"))
(ext:quit 0)
