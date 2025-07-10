;; Decomposition Monitoring Contract
;; Tracks mulch breakdown and replacement needs

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u500))
(define-constant ERR-MONITORING-NOT-FOUND (err u501))
(define-constant ERR-INVALID-MEASUREMENT (err u502))
(define-constant ERR-GARDEN-NOT-REGISTERED (err u503))

;; Data Variables
(define-data-var next-garden-id uint u1)
(define-data-var next-measurement-id uint u1)
(define-data-var replacement-threshold uint u30)

;; Data Maps
(define-map monitored-gardens
  { garden-id: uint }
  {
    owner: principal,
    location: (string-ascii 100),
    initial-mulch-type: (string-ascii 30),
    initial-depth: uint,
    application-date: uint,
    garden-size: uint,
    soil-type: (string-ascii 20),
    active: bool
  }
)

(define-map decomposition-measurements
  { measurement-id: uint }
  {
    garden-id: uint,
    measurement-date: uint,
    current-depth: uint,
    decomposition-rate: uint,
    soil-ph: uint,
    moisture-level: uint,
    nutrient-release: uint,
    weed-suppression: uint
  }
)

(define-map mulch-decomposition-rates
  { mulch-type: (string-ascii 30), soil-type: (string-ascii 20) }
  {
    expected-monthly-rate: uint,
    nutrient-release-pattern: (list 12 uint),
    optimal-replacement-months: uint,
    soil-improvement-factor: uint
  }
)

(define-map replacement-notifications
  { garden-id: uint }
  {
    notification-date: uint,
    current-depth: uint,
    recommended-action: (string-ascii 50),
    urgency-level: uint,
    estimated-cost: uint
  }
)

;; Public Functions

;; Register garden for monitoring
(define-public (register-garden
  (location (string-ascii 100))
  (mulch-type (string-ascii 30))
  (initial-depth uint)
  (garden-size uint)
  (soil-type (string-ascii 20))
)
  (let ((garden-id (var-get next-garden-id)))
    (map-set monitored-gardens
      { garden-id: garden-id }
      {
        owner: tx-sender,
        location: location,
        initial-mulch-type: mulch-type,
        initial-depth: initial-depth,
        application-date: block-height,
        garden-size: garden-size,
        soil-type: soil-type,
        active: true
      }
    )
    (var-set next-garden-id (+ garden-id u1))
    (ok garden-id)
  )
)

;; Record decomposition measurement
(define-public (record-measurement
  (garden-id uint)
  (current-depth uint)
  (decomp-rate uint)
  (ph-level uint)
  (moisture uint)
  (nutrients uint)
  (weed-suppression uint)
)
  (let ((measurement-id (var-get next-measurement-id))
        (garden (unwrap! (map-get? monitored-gardens { garden-id: garden-id }) ERR-GARDEN-NOT-REGISTERED)))
    (asserts! (is-eq tx-sender (get owner garden)) ERR-UNAUTHORIZED)
    (asserts! (get active garden) ERR-GARDEN-NOT-REGISTERED)
    (asserts! (<= current-depth (get initial-depth garden)) ERR-INVALID-MEASUREMENT)
    (map-set decomposition-measurements
      { measurement-id: measurement-id }
      {
        garden-id: garden-id,
        measurement-date: block-height,
        current-depth: current-depth,
        decomposition-rate: decomp-rate,
        soil-ph: ph-level,
        moisture-level: moisture,
        nutrient-release: nutrients,
        weed-suppression: weed-suppression
      }
    )
    (var-set next-measurement-id (+ measurement-id u1))
    (check-replacement-need garden-id current-depth)
    (ok measurement-id)
  )
)

;; Set decomposition rates for mulch types
(define-public (set-decomposition-rates
  (mulch-type (string-ascii 30))
  (soil-type (string-ascii 20))
  (monthly-rate uint)
  (nutrient-pattern (list 12 uint))
  (replacement-months uint)
  (improvement-factor uint)
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (map-set mulch-decomposition-rates
      { mulch-type: mulch-type, soil-type: soil-type }
      {
        expected-monthly-rate: monthly-rate,
        nutrient-release-pattern: nutrient-pattern,
        optimal-replacement-months: replacement-months,
        soil-improvement-factor: improvement-factor
      }
    )
    (ok true)
  )
)

;; Update replacement threshold
(define-public (update-replacement-threshold (new-threshold uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (var-set replacement-threshold new-threshold)
    (ok true)
  )
)

;; Generate replacement notification
(define-public (create-replacement-notification
  (garden-id uint)
  (current-depth uint)
  (action (string-ascii 50))
  (urgency uint)
  (cost uint)
)
  (let ((garden (unwrap! (map-get? monitored-gardens { garden-id: garden-id }) ERR-GARDEN-NOT-REGISTERED)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (map-set replacement-notifications
      { garden-id: garden-id }
      {
        notification-date: block-height,
        current-depth: current-depth,
        recommended-action: action,
        urgency-level: urgency,
        estimated-cost: cost
      }
    )
    (ok true)
  )
)

;; Private Functions

(define-private (check-replacement-need (garden-id uint) (current-depth uint))
  (let ((threshold-percentage (var-get replacement-threshold)))
    (let ((garden (unwrap-panic (map-get? monitored-gardens { garden-id: garden-id }))))
      (let ((initial-depth (get initial-depth garden))
            (remaining-percentage (/ (* current-depth u100) initial-depth)))
        (if (<= remaining-percentage threshold-percentage)
          (map-set replacement-notifications
            { garden-id: garden-id }
            {
              notification-date: block-height,
              current-depth: current-depth,
              recommended-action: "replacement-needed",
              urgency-level: u3,
              estimated-cost: u0
            }
          )
          true
        )
      )
    )
  )
)

;; Read-only Functions

(define-read-only (get-garden (garden-id uint))
  (map-get? monitored-gardens { garden-id: garden-id })
)

(define-read-only (get-measurement (measurement-id uint))
  (map-get? decomposition-measurements { measurement-id: measurement-id })
)

(define-read-only (get-decomposition-rates (mulch-type (string-ascii 30)) (soil-type (string-ascii 20)))
  (map-get? mulch-decomposition-rates { mulch-type: mulch-type, soil-type: soil-type })
)

(define-read-only (get-replacement-notification (garden-id uint))
  (map-get? replacement-notifications { garden-id: garden-id })
)

(define-read-only (get-replacement-threshold)
  (var-get replacement-threshold)
)

(define-read-only (calculate-expected-lifespan (mulch-type (string-ascii 30)) (soil-type (string-ascii 20)) (initial-depth uint))
  (match (map-get? mulch-decomposition-rates { mulch-type: mulch-type, soil-type: soil-type })
    rates (let ((monthly-rate (get expected-monthly-rate rates)))
            (some (/ (* initial-depth u12) monthly-rate)))
    none
  )
)

(define-read-only (needs-replacement (garden-id uint))
  (is-some (map-get? replacement-notifications { garden-id: garden-id }))
)
