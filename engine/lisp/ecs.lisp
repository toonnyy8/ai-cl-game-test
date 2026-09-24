;;;; ecs.lisp — a tiny Entity-Component-System, plus an event queue for talking between systems.
;;;;
;;;; Game objects differ by the data they carry, not by class: the hero, a grunt and a thrown
;;;; kunai all have a position, only fighters have hit points, only the kunai is a projectile.
;;;; So instead of a class hierarchy:
;;;;
;;;;   entity    = a handle (a fixnum). It has no data of its own.
;;;;   component = a plain struct defined with DEFCOMPONENT. An entity has at most one of each kind.
;;;;   system    = an ordinary function that visits every entity having some components
;;;;               (DO-ENTITIES) and updates them. A frame = the systems, called in a fixed order.
;;;;
;;;;   (defcomponent health (hp 100f0 :type single-float))
;;;;   (defcomponent poison (dps 5f0 :type single-float))
;;;;   (spawn-entity (make-health :hp 60f0) (make-poison))
;;;;   (defun poison-system (dt)
;;;;     (do-entities (e (h health) (p poison))
;;;;       (decf (health-hp h) (* dt (poison-dps p)))
;;;;       (when (<= (health-hp h) 0) (emit :died e) (destroy-entity e))))
;;;;
;;;; Storage: one vector per component kind, indexed by the entity's slot, so (HEALTH e) is two
;;;; array reads. Slots are reused after DESTROY-ENTITY; the handle also carries the slot's
;;;; generation, so a handle kept after its entity died stops matching: ENTITY-ALIVE-P is NIL and
;;;; every component getter returns NIL. Holding handles in other components is therefore safe.
;;;;
;;;; The world is global state (one per program). This file is plain Common Lisp: it also runs
;;;; on the host ECL (tests/ecs-test.lisp).
(in-package :engine)

(defconstant +max-entities+ 256 "Entity slots. A handle = slot + 256 x generation.")
(defconstant +max-component-kinds+ 64)

(declaim (type simple-vector *stores*)
         (type (simple-array fixnum (*)) *generation*)
         (type simple-bit-vector *used*)
         (type fixnum *top*))
(defvar *stores* (make-array +max-component-kinds+ :initial-element nil)
  "Component kind index -> simple-vector of +MAX-ENTITIES+ components (NIL = absent).")
(defvar *generation* (make-array +max-entities+ :element-type 'fixnum :initial-element 0))
(defvar *used* (make-array +max-entities+ :element-type 'bit :initial-element 0))
(defvar *top* 0 "One past the highest slot in use: DO-ENTITIES scans slots below it.")

;;; Component kinds get a store index when DEFCOMPONENT is compiled (it is baked into the getter)
;;; and again, in the same order, when it is loaded.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defvar *component-kinds* nil "Component names, in definition order (the store index).")
  (defun component-kind-index (name)
    (or (position name *component-kinds*)
        (progn (when (>= (length *component-kinds*) +max-component-kinds+)
                 (error "ecs: more than ~d component kinds" +max-component-kinds+))
               (setf *component-kinds* (append *component-kinds* (list name)))
               (1- (length *component-kinds*))))))

(defun %register-kind (name index)
  (setf (get name 'component-index) index)
  (unless (svref *stores* index)
    (setf (svref *stores* index) (make-array +max-entities+ :initial-element nil))))

;;; ---------------------------------------------------------------- handles
(declaim (inline handle-slot entity-alive-p %component))
(defun handle-slot (e) (logand e (1- +max-entities+)))

(defun entity-alive-p (e)
  "T while E is the handle of an existing entity (NIL for NIL, destroyed or reused handles)."
  (and (typep e 'fixnum) (>= e 0)
       (let ((s (handle-slot e)))
         (and (= 1 (sbit *used* s)) (= (aref *generation* s) (ash e -8))))))

(defun %component (e index)
  (and (entity-alive-p e) (svref (svref *stores* index) (handle-slot e))))

;;; ---------------------------------------------------------------- components
(defmacro defcomponent (name &rest slots)
  "Define component NAME: a struct (MAKE-NAME, NAME-SLOT accessors, like DEFSTRUCT) plus the
getter (NAME entity) that returns the entity's component or NIL. An optional docstring may
come first. Slots are DEFSTRUCT slot descriptions: (slot default :type type)."
  (let ((doc (when (stringp (first slots)) (list (pop slots))))
        (index (component-kind-index name)))
    `(progn
       (eval-when (:compile-toplevel :load-toplevel :execute) (component-kind-index ',name))
       (defstruct (,name (:copier nil) (:predicate nil)) ,@doc ,@slots)
       (%register-kind ',name ,index)
       (declaim (inline ,name))
       (defun ,name (e) ,(format nil "The ~(~a~) component of entity E, or NIL." name) (%component e ,index))
       ',name)))

(defun add-component (e component)
  "Attach COMPONENT (a struct made by a DEFCOMPONENT constructor) to E, replacing one of the same kind."
  (let ((index (get (type-of component) 'component-index)))
    (unless index (error "ecs: ~s is not a component" component))
    (unless (entity-alive-p e) (error "ecs: entity ~s is not alive" e))
    (setf (svref (svref *stores* index) (handle-slot e)) component)))

(defun remove-component (e kind)
  "Detach the component of KIND (its name, a symbol) from E, if it has one."
  (when (entity-alive-p e)
    (setf (svref (svref *stores* (get kind 'component-index)) (handle-slot e)) nil)))

;;; ---------------------------------------------------------------- entities
(defun spawn-entity (&rest components)
  "A new entity with COMPONENTS attached; returns its handle."
  (let ((s (position 0 *used*)))
    (unless s (error "ecs: more than ~d entities" +max-entities+))
    (setf (sbit *used* s) 1 *top* (max *top* (1+ s)))
    (let ((e (+ s (* +max-entities+ (aref *generation* s)))))
      (dolist (c components e) (add-component e c)))))

(defun destroy-entity (e)
  "Remove E and all its components. Its handle (and any copy of it) stops matching."
  (when (entity-alive-p e)
    (let ((s (handle-slot e)))
      (dotimes (i (length *component-kinds*))
        (setf (svref (svref *stores* i) s) nil))
      (setf (sbit *used* s) 0
            (aref *generation* s) (logand (1+ (aref *generation* s)) #xFFFFF))
      (loop while (and (> *top* 0) (= 0 (sbit *used* (1- *top*)))) do (decf *top*))))
  nil)

(defun clear-entities ()
  "Destroy every entity (new level, restart)."
  (dotimes (s *top*)
    (when (= 1 (sbit *used* s)) (destroy-entity (+ s (* +max-entities+ (aref *generation* s)))))))

(defmacro do-entities ((e &rest components) &body body)
  "Run BODY once for every entity having all COMPONENTS, in slot order, with E bound to its
handle. Each component spec is a name (bound to a variable of the same name) or (var name).
Entities spawned while the loop runs may or may not be visited in this pass."
  (let* ((specs (mapcar (lambda (c) (if (consp c) c (list c c))) components))
         (stores (loop repeat (length specs) collect (gensym "STORE")))
         (s (gensym "SLOT")))
    `(let ,(loop for (nil kind) in specs for st in stores
                 collect `(,st (svref *stores* ,(or (position kind *component-kinds*)
                                                    (error "do-entities: unknown component ~s" kind)))))
       (declare (type simple-vector ,@stores))
       (dotimes (,s *top*)
         (when (= 1 (sbit *used* ,s))
           (let ,(loop for (var) in specs for st in stores collect `(,var (svref ,st ,s)))
             (when (and ,@(mapcar #'first specs))
               (let ((,e (+ ,s (* +max-entities+ (aref *generation* ,s)))))
                 (declare (ignorable ,e))
                 ,@body))))))))

;;; ---------------------------------------------------------------- events
;;; Systems report what happened as small lists, (kind . data), e.g. (:hit attacker target 12.0).
;;; Another system reads them later in the frame and reacts (sound, particles, score), so the
;;; rules that decide never call the code that shows.
(defvar *events* nil "Events emitted since the last TAKE-EVENTS, newest first.")

(defun emit (kind &rest data)
  "Queue the event (KIND . DATA)."
  (push (cons kind data) *events*)
  nil)

(defun take-events ()
  "All queued events, oldest first; the queue is emptied."
  (prog1 (nreverse *events*) (setf *events* nil)))
