;; Gaming Rewards Distribution Smart Contract

;; Constants
(define-constant game-master tx-sender)
(define-constant err-master-only (err u100))
(define-constant err-reward-taken (err u101))
(define-constant err-not-qualified (err u102))
(define-constant err-no-reward-pool (err u103))
(define-constant err-distribution-locked (err u104))
(define-constant err-invalid-player (err u105))
(define-constant err-invalid-reward (err u106))

;; Data Variables
(define-data-var total-reward-pool uint u5000000)
(define-data-var distribution-active bool false)

;; Data Maps
(define-map player-rewards principal uint)           ;; Maps players to their reward points
(define-map rewards-collected principal bool)        ;; Tracks if player collected rewards
(define-map achievement-holders principal bool)      ;; Achievement-based qualification
(define-map verified-players principal bool)         ;; Verified player accounts

;; Private Functions
(define-private (is-game-master)
    (is-eq tx-sender game-master))

(define-private (is-qualified-player (player principal))
    (and 
        (is-some (map-get? verified-players player))
        (is-some (map-get? achievement-holders player))))

(define-private (validate-player (player principal))
    (and
        (is-some (some player))
        (not (is-eq player game-master))))

;; Public Functions

;; Verify player account (master only)
(define-public (verify-player (player principal))
    (begin
        (asserts! (is-game-master) err-master-only)
        (asserts! (validate-player player) err-invalid-player)
        (ok (map-set verified-players player true))))

;; Revoke player verification (master only)
(define-public (revoke-verification (player principal))
    (begin
        (asserts! (is-game-master) err-master-only)
        (asserts! (validate-player player) err-invalid-player)
        (ok (map-set verified-players player false))))

;; Grant achievement (master only)
(define-public (grant-achievement (player principal) (has-achievement bool))
    (begin
        (asserts! (is-game-master) err-master-only)
        (asserts! (validate-player player) err-invalid-player)
        (ok (map-set achievement-holders player has-achievement))))

;; Set reward points for a player (master only)
(define-public (set-reward-points (player principal) (points uint))
    (begin
        (asserts! (is-game-master) err-master-only)
        (asserts! (validate-player player) err-invalid-player)
        (asserts! (> points u0) err-invalid-reward)
        (asserts! (<= points (var-get total-reward-pool)) err-invalid-reward)
        (ok (map-set player-rewards player points))))

;; Collect rewards (public)
(define-public (collect-rewards)
    (let ((player tx-sender)
          (reward-amount (unwrap! (map-get? player-rewards player) err-no-reward-pool)))
        (begin
            (asserts! (var-get distribution-active) err-distribution-locked)
            (asserts! (is-qualified-player player) err-not-qualified)
            (asserts! (not (default-to false (map-get? rewards-collected player))) err-reward-taken)
            (map-set rewards-collected player true)
            (ok reward-amount))))

;; Batch reward distribution (master only)
(define-public (mass-distribute (players (list 200 principal)) (points (list 200 uint)))
    (begin
        (asserts! (is-game-master) err-master-only)
        (asserts! (is-eq (len players) (len points)) err-invalid-reward)
        (asserts! 
            (fold and 
                (map validate-player players) 
                true) 
            err-invalid-player)
        (asserts! 
            (fold and 
                (map is-valid-points points)
                true) 
            err-invalid-reward)
        (ok true)))

(define-private (is-valid-points (points uint))
    (> points u0))

;; Toggle distribution status (master only)
(define-public (toggle-distribution)
    (begin
        (asserts! (is-game-master) err-master-only)
        (ok (var-set distribution-active (not (var-get distribution-active))))))

;; Read-only functions

(define-read-only (get-player-rewards (player principal))
    (default-to u0 (map-get? player-rewards player)))

(define-read-only (has-collected (player principal))
    (default-to false (map-get? rewards-collected player)))

(define-read-only (check-qualification (player principal))
    (is-qualified-player player))

(define-read-only (get-distribution-status)
    (var-get distribution-active))

(define-read-only (get-reward-pool)
    (var-get total-reward-pool))

(define-read-only (get-player-status (player principal))
    {
        rewards: (get-player-rewards player),
        collected: (has-collected player),
        qualified: (check-qualification player),
        verified: (default-to false (map-get? verified-players player)),
        has-achievement: (default-to false (map-get? achievement-holders player)),
        can-collect: (and 
            (var-get distribution-active)
            (check-qualification player)
            (not (has-collected player))
            (> (get-player-rewards player) u0)
        )
    })