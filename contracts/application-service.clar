;; Application Service Contract
;; Coordinates mulch spreading and garden bed preparation

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u200))
(define-constant ERR-SERVICE-NOT-FOUND (err u201))
(define-constant ERR-BOOKING-NOT-FOUND (err u202))
(define-constant ERR-INVALID-STATUS (err u203))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u204))

;; Data Variables
(define-data-var next-provider-id uint u1)
(define-data-var next-booking-id uint u1)
(define-data-var service-fee-percentage uint u5)

;; Data Maps
(define-map service-providers
  { provider-id: uint }
  {
    owner: principal,
    name: (string-ascii 50),
    service-area: (string-ascii 100),
    hourly-rate: uint,
    equipment-available: (list 10 (string-ascii 30)),
    rating: uint,
    jobs-completed: uint,
    active: bool
  }
)

(define-map service-bookings
  { booking-id: uint }
  {
    customer: principal,
    provider-id: uint,
    garden-size: uint,
    service-type: (string-ascii 30),
    scheduled-date: uint,
    estimated-hours: uint,
    total-cost: uint,
    status: (string-ascii 20),
    completion-date: (optional uint)
  }
)

(define-map garden-preparations
  { booking-id: uint }
  {
    soil-testing-required: bool,
    weed-removal: bool,
    bed-edging: bool,
    irrigation-check: bool,
    mulch-type-preference: (string-ascii 30),
    special-instructions: (string-ascii 200)
  }
)

;; Public Functions

;; Register as service provider
(define-public (register-provider
  (name (string-ascii 50))
  (service-area (string-ascii 100))
  (hourly-rate uint)
  (equipment (list 10 (string-ascii 30)))
)
  (let ((provider-id (var-get next-provider-id)))
    (map-set service-providers
      { provider-id: provider-id }
      {
        owner: tx-sender,
        name: name,
        service-area: service-area,
        hourly-rate: hourly-rate,
        equipment-available: equipment,
        rating: u100,
        jobs-completed: u0,
        active: true
      }
    )
    (var-set next-provider-id (+ provider-id u1))
    (ok provider-id)
  )
)

;; Book mulch application service
(define-public (book-service
  (provider-id uint)
  (garden-size uint)
  (service-type (string-ascii 30))
  (scheduled-date uint)
  (estimated-hours uint)
  (payment-amount uint)
)
  (let ((booking-id (var-get next-booking-id))
        (provider (unwrap! (map-get? service-providers { provider-id: provider-id }) ERR-SERVICE-NOT-FOUND)))
    (asserts! (get active provider) ERR-SERVICE-NOT-FOUND)
    (let ((total-cost (* (get hourly-rate provider) estimated-hours)))
      (asserts! (>= payment-amount total-cost) ERR-INSUFFICIENT-PAYMENT)
      (map-set service-bookings
        { booking-id: booking-id }
        {
          customer: tx-sender,
          provider-id: provider-id,
          garden-size: garden-size,
          service-type: service-type,
          scheduled-date: scheduled-date,
          estimated-hours: estimated-hours,
          total-cost: total-cost,
          status: "booked",
          completion-date: none
        }
      )
      (var-set next-booking-id (+ booking-id u1))
      (ok booking-id)
    )
  )
)

;; Set garden preparation requirements
(define-public (set-preparation-requirements
  (booking-id uint)
  (soil-testing bool)
  (weed-removal bool)
  (bed-edging bool)
  (irrigation-check bool)
  (mulch-preference (string-ascii 30))
  (instructions (string-ascii 200))
)
  (let ((booking (unwrap! (map-get? service-bookings { booking-id: booking-id }) ERR-BOOKING-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get customer booking)) ERR-UNAUTHORIZED)
    (map-set garden-preparations
      { booking-id: booking-id }
      {
        soil-testing-required: soil-testing,
        weed-removal: weed-removal,
        bed-edging: bed-edging,
        irrigation-check: irrigation-check,
        mulch-type-preference: mulch-preference,
        special-instructions: instructions
      }
    )
    (ok true)
  )
)

;; Update booking status
(define-public (update-booking-status (booking-id uint) (new-status (string-ascii 20)))
  (let ((booking (unwrap! (map-get? service-bookings { booking-id: booking-id }) ERR-BOOKING-NOT-FOUND))
        (provider (unwrap! (map-get? service-providers { provider-id: (get provider-id booking) }) ERR-SERVICE-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner provider)) ERR-UNAUTHORIZED)
    (map-set service-bookings
      { booking-id: booking-id }
      (merge booking {
        status: new-status,
        completion-date: (if (is-eq new-status "completed") (some block-height) none)
      })
    )
    (if (is-eq new-status "completed")
      (map-set service-providers
        { provider-id: (get provider-id booking) }
        (merge provider { jobs-completed: (+ (get jobs-completed provider) u1) })
      )
      true
    )
    (ok true)
  )
)

;; Rate service provider
(define-public (rate-provider (booking-id uint) (rating uint))
  (let ((booking (unwrap! (map-get? service-bookings { booking-id: booking-id }) ERR-BOOKING-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get customer booking)) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get status booking) "completed") ERR-INVALID-STATUS)
    (asserts! (and (>= rating u1) (<= rating u5)) ERR-INVALID-STATUS)
    (ok true)
  )
)

;; Read-only Functions

(define-read-only (get-provider (provider-id uint))
  (map-get? service-providers { provider-id: provider-id })
)

(define-read-only (get-booking (booking-id uint))
  (map-get? service-bookings { booking-id: booking-id })
)

(define-read-only (get-preparation-requirements (booking-id uint))
  (map-get? garden-preparations { booking-id: booking-id })
)

(define-read-only (get-next-provider-id)
  (var-get next-provider-id)
)

(define-read-only (get-next-booking-id)
  (var-get next-booking-id)
)
