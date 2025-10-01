;; ChainTrace - Supply Chain Tracking Smart Contract
;; A decentralized supply chain tracker anchored to Bitcoin via Stacks

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-status (err u104))

;; Data Variables
(define-data-var product-counter uint u0)

;; Product status types
(define-constant STATUS-MANUFACTURED u1)
(define-constant STATUS-IN-TRANSIT u2)
(define-constant STATUS-DELIVERED u3)
(define-constant STATUS-VERIFIED u4)

;; Data Maps
(define-map products
  { product-id: uint }
  {
    name: (string-ascii 100),
    manufacturer: principal,
    manufacture-date: uint,
    current-holder: principal,
    status: uint,
    qr-code: (string-ascii 64),
    active: bool
  }
)

(define-map product-history
  { product-id: uint, event-id: uint }
  {
    actor: principal,
    action: (string-ascii 50),
    timestamp: uint,
    location: (string-ascii 100),
    notes: (string-ascii 200)
  }
)

(define-map product-event-counter
  { product-id: uint }
  { count: uint }
)

(define-map authorized-verifiers
  { verifier: principal }
  { authorized: bool }
)

;; Authorization Functions
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set authorized-verifiers { verifier: verifier } { authorized: true }))
  )
)

(define-public (remove-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set authorized-verifiers { verifier: verifier } { authorized: false }))
  )
)

(define-read-only (is-verifier (verifier principal))
  (default-to false (get authorized (map-get? authorized-verifiers { verifier: verifier })))
)

;; Product Registration
(define-public (register-product 
  (name (string-ascii 100))
  (qr-code (string-ascii 64))
  (location (string-ascii 100)))
  (let
    (
      (product-id (+ (var-get product-counter) u1))
      (timestamp block-height)
    )
    (asserts! (is-none (map-get? products { product-id: product-id })) err-already-exists)
    
    ;; Create product
    (map-set products
      { product-id: product-id }
      {
        name: name,
        manufacturer: tx-sender,
        manufacture-date: timestamp,
        current-holder: tx-sender,
        status: STATUS-MANUFACTURED,
        qr-code: qr-code,
        active: true
      }
    )
    
    ;; Initialize event counter
    (map-set product-event-counter
      { product-id: product-id }
      { count: u0 }
    )
    
    ;; Record first event
    (add-product-event product-id "MANUFACTURED" location "Product registered on ChainTrace")
    
    ;; Increment counter
    (var-set product-counter product-id)
    (ok product-id)
  )
)

;; Transfer Product
(define-public (transfer-product 
  (product-id uint)
  (new-holder principal)
  (location (string-ascii 100))
  (notes (string-ascii 200)))
  (let
    (
      (product (unwrap! (map-get? products { product-id: product-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get current-holder product)) err-unauthorized)
    (asserts! (get active product) err-invalid-status)
    
    ;; Update product holder and status
    (map-set products
      { product-id: product-id }
      (merge product { 
        current-holder: new-holder,
        status: STATUS-IN-TRANSIT
      })
    )
    
    ;; Record transfer event
    (add-product-event product-id "TRANSFERRED" location notes)
    (ok true)
  )
)

;; Confirm Delivery
(define-public (confirm-delivery 
  (product-id uint)
  (location (string-ascii 100))
  (notes (string-ascii 200)))
  (let
    (
      (product (unwrap! (map-get? products { product-id: product-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get current-holder product)) err-unauthorized)
    (asserts! (get active product) err-invalid-status)
    
    ;; Update status to delivered
    (map-set products
      { product-id: product-id }
      (merge product { status: STATUS-DELIVERED })
    )
    
    ;; Record delivery event
    (add-product-event product-id "DELIVERED" location notes)
    (ok true)
  )
)

;; Verify Product (by authorized verifiers)
(define-public (verify-product 
  (product-id uint)
  (location (string-ascii 100))
  (notes (string-ascii 200)))
  (let
    (
      (product (unwrap! (map-get? products { product-id: product-id }) err-not-found))
    )
    (asserts! (is-verifier tx-sender) err-unauthorized)
    (asserts! (get active product) err-invalid-status)
    
    ;; Update status to verified
    (map-set products
      { product-id: product-id }
      (merge product { status: STATUS-VERIFIED })
    )
    
    ;; Record verification event
    (add-product-event product-id "VERIFIED" location notes)
    (ok true)
  )
)

;; Add Product Event (internal)
(define-private (add-product-event
  (product-id uint)
  (action (string-ascii 50))
  (location (string-ascii 100))
  (notes (string-ascii 200)))
  (let
    (
      (counter (default-to { count: u0 } (map-get? product-event-counter { product-id: product-id })))
      (event-id (+ (get count counter) u1))
    )
    (map-set product-history
      { product-id: product-id, event-id: event-id }
      {
        actor: tx-sender,
        action: action,
        timestamp: block-height,
        location: location,
        notes: notes
      }
    )
    
    (map-set product-event-counter
      { product-id: product-id }
      { count: event-id }
    )
    true
  )
)

;; Read-only Functions
(define-read-only (get-product (product-id uint))
  (ok (map-get? products { product-id: product-id }))
)

(define-read-only (get-product-event (product-id uint) (event-id uint))
  (ok (map-get? product-history { product-id: product-id, event-id: event-id }))
)

(define-read-only (get-event-count (product-id uint))
  (ok (default-to { count: u0 } (map-get? product-event-counter { product-id: product-id })))
)

(define-read-only (get-product-counter)
  (ok (var-get product-counter))
)

(define-read-only (verify-qr-code (product-id uint) (qr-code (string-ascii 64)))
  (match (map-get? products { product-id: product-id })
    product (ok (is-eq (get qr-code product) qr-code))
    (ok false)
  )
)