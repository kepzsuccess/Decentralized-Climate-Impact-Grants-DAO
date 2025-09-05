(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROPOSAL-EXISTS (err u101))
(define-constant ERR-NO-PROPOSAL (err u102))
(define-constant ERR-VOTING-CLOSED (err u103))
(define-constant ERR-ALREADY-VOTED (err u104))
(define-constant ERR-INSUFFICIENT-FUNDS (err u105))
(define-constant ERR-NOT-ACTIVE (err u106))
(define-constant ERR-PAUSED (err u107))
(define-constant ERR-NO-MILESTONE (err u108))
(define-constant ERR-MILESTONE-COMPLETED (err u109))
(define-constant ERR-INVALID-MILESTONE (err u110))
(define-constant ERR-ALREADY-STAKED (err u111))
(define-constant ERR-NO-STAKE (err u112))
(define-constant ERR-STAKE-NOT-WITHDRAWABLE (err u113))

(define-data-var dao-owner principal tx-sender)
(define-data-var proposal-count uint u0)
(define-data-var min-proposal-amount uint u1000000)
(define-data-var voting-period uint u144)
(define-data-var paused bool false)
(define-data-var milestone-count uint u0)

(define-map proposals
    uint
    {
        creator: principal,
        title: (string-ascii 100),
        description: (string-ascii 500),
        amount: uint,
        recipient: principal,
        yes-votes: uint,
        no-votes: uint,
        status: (string-ascii 20),
        start-block: uint,
        end-block: uint,
    }
)

(define-map votes
    {
        proposal-id: uint,
        voter: principal,
    }
    bool
)

(define-map milestones
    uint
    {
        proposal-id: uint,
        description: (string-ascii 200),
        amount: uint,
        completed: bool,
        verified-by: (optional principal),
    }
)

(define-map proposal-stakes
    {
        proposal-id: uint,
        staker: principal,
    }
    uint
)

(define-map proposal-total-stakes
    uint
    uint
)

(define-read-only (get-proposal (id uint))
    (map-get? proposals id)
)

(define-read-only (get-vote
        (proposal-id uint)
        (voter principal)
    )
    (map-get? votes {
        proposal-id: proposal-id,
        voter: voter,
    })
)

(define-read-only (get-proposal-count)
    (var-get proposal-count)
)

(define-read-only (is-paused)
    (var-get paused)
)

(define-read-only (get-milestone (id uint))
    (map-get? milestones id)
)

(define-read-only (get-milestone-count)
    (var-get milestone-count)
)

(define-read-only (get-stake
        (proposal-id uint)
        (staker principal)
    )
    (map-get? proposal-stakes {
        proposal-id: proposal-id,
        staker: staker,
    })
)

(define-read-only (get-total-stakes (proposal-id uint))
    (default-to u0 (map-get? proposal-total-stakes proposal-id))
)

(define-public (create-proposal
        (title (string-ascii 100))
        (description (string-ascii 500))
        (amount uint)
        (recipient principal)
    )
    (let ((proposal-id (+ (var-get proposal-count) u1)))
        (asserts! (not (var-get paused)) ERR-PAUSED)
        (asserts! (>= amount (var-get min-proposal-amount))
            ERR-INSUFFICIENT-FUNDS
        )
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (map-set proposals proposal-id {
            creator: tx-sender,
            title: title,
            description: description,
            amount: amount,
            recipient: recipient,
            yes-votes: u0,
            no-votes: u0,
            status: "active",
            start-block: stacks-block-height,
            end-block: (+ stacks-block-height (var-get voting-period)),
        })
        (var-set proposal-count proposal-id)
        (ok proposal-id)
    )
)

(define-public (vote
        (proposal-id uint)
        (vote-bool bool)
    )
    (let ((proposal (unwrap! (get-proposal proposal-id) ERR-NO-PROPOSAL)))
        (asserts! (not (var-get paused)) ERR-PAUSED)
        (asserts! (is-eq (get-vote proposal-id tx-sender) none) ERR-ALREADY-VOTED)
        (asserts! (< stacks-block-height (get end-block proposal))
            ERR-VOTING-CLOSED
        )
        (asserts! (is-eq (get status proposal) "active") ERR-NOT-ACTIVE)
        (map-set votes {
            proposal-id: proposal-id,
            voter: tx-sender,
        }
            vote-bool
        )
        (if vote-bool
            (map-set proposals proposal-id
                (merge proposal { yes-votes: (+ (get yes-votes proposal) u1) })
            )
            (map-set proposals proposal-id
                (merge proposal { no-votes: (+ (get no-votes proposal) u1) })
            )
        )
        (ok true)
    )
)

(define-public (finalize-proposal (proposal-id uint))
    (let ((proposal (unwrap! (get-proposal proposal-id) ERR-NO-PROPOSAL)))
        (asserts! (>= stacks-block-height (get end-block proposal))
            ERR-VOTING-CLOSED
        )
        (asserts! (is-eq (get status proposal) "active") ERR-NOT-ACTIVE)
        (if (> (get yes-votes proposal) (get no-votes proposal))
            (begin
                (try! (as-contract (stx-transfer? (get amount proposal) tx-sender
                    (get recipient proposal)
                )))
                (map-set proposals proposal-id
                    (merge proposal { status: "approved" })
                )
                (ok true)
            )
            (begin
                (try! (as-contract (stx-transfer? (get amount proposal) tx-sender
                    (get creator proposal)
                )))
                (map-set proposals proposal-id
                    (merge proposal { status: "rejected" })
                )
                (ok true)
            )
        )
    )
)
(define-public (update-voting-period (new-period uint))
    (begin
        (asserts! (is-eq tx-sender (var-get dao-owner)) ERR-NOT-AUTHORIZED)
        (var-set voting-period new-period)
        (ok true)
    )
)

(define-public (update-min-proposal-amount (new-amount uint))
    (begin
        (asserts! (is-eq tx-sender (var-get dao-owner)) ERR-NOT-AUTHORIZED)
        (var-set min-proposal-amount new-amount)
        (ok true)
    )
)

(define-public (transfer-ownership (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get dao-owner)) ERR-NOT-AUTHORIZED)
        (var-set dao-owner new-owner)
        (ok true)
    )
)

(define-public (pause-dao)
    (begin
        (asserts! (is-eq tx-sender (var-get dao-owner)) ERR-NOT-AUTHORIZED)
        (var-set paused true)
        (ok true)
    )
)

(define-public (unpause-dao)
    (begin
        (asserts! (is-eq tx-sender (var-get dao-owner)) ERR-NOT-AUTHORIZED)
        (var-set paused false)
        (ok true)
    )
)

(define-public (create-milestone
        (proposal-id uint)
        (description (string-ascii 200))
        (amount uint)
    )
    (let (
            (milestone-id (+ (var-get milestone-count) u1))
            (proposal (unwrap! (get-proposal proposal-id) ERR-NO-PROPOSAL))
        )
        (asserts! (not (var-get paused)) ERR-PAUSED)
        (asserts! (is-eq tx-sender (get creator proposal)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status proposal) "approved") ERR-NOT-ACTIVE)
        (map-set milestones milestone-id {
            proposal-id: proposal-id,
            description: description,
            amount: amount,
            completed: false,
            verified-by: none,
        })
        (var-set milestone-count milestone-id)
        (ok milestone-id)
    )
)

(define-public (complete-milestone (milestone-id uint))
    (let (
            (milestone (unwrap! (get-milestone milestone-id) ERR-NO-MILESTONE))
            (proposal (unwrap! (get-proposal (get proposal-id milestone)) ERR-NO-PROPOSAL))
        )
        (asserts! (not (var-get paused)) ERR-PAUSED)
        (asserts! (is-eq tx-sender (get creator proposal)) ERR-NOT-AUTHORIZED)
        (asserts! (not (get completed milestone)) ERR-MILESTONE-COMPLETED)
        (map-set milestones milestone-id (merge milestone { completed: true }))
        (ok true)
    )
)

(define-public (verify-milestone (milestone-id uint))
    (let ((milestone (unwrap! (get-milestone milestone-id) ERR-NO-MILESTONE)))
        (asserts! (not (var-get paused)) ERR-PAUSED)
        (asserts! (is-eq tx-sender (var-get dao-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (get completed milestone) ERR-INVALID-MILESTONE)
        (try! (as-contract (stx-transfer? (get amount milestone) tx-sender
            (get creator
                (unwrap! (get-proposal (get proposal-id milestone))
                    ERR-NO-PROPOSAL
                ))
        )))
        (map-set milestones milestone-id
            (merge milestone { verified-by: (some tx-sender) })
        )
        (ok true)
    )
)

(define-public (stake-proposal
        (proposal-id uint)
        (amount uint)
    )
    (let (
            (proposal (unwrap! (get-proposal proposal-id) ERR-NO-PROPOSAL))
            (current-stake (default-to u0 (get-stake proposal-id tx-sender)))
            (current-total (get-total-stakes proposal-id))
        )
        (asserts! (not (var-get paused)) ERR-PAUSED)
        (asserts! (> amount u0) ERR-INSUFFICIENT-FUNDS)
        (asserts! (is-eq current-stake u0) ERR-ALREADY-STAKED)
        (asserts! (is-eq (get status proposal) "active") ERR-NOT-ACTIVE)
        (asserts! (< stacks-block-height (get end-block proposal))
            ERR-VOTING-CLOSED
        )
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (map-set proposal-stakes {
            proposal-id: proposal-id,
            staker: tx-sender,
        }
            amount
        )
        (map-set proposal-total-stakes proposal-id (+ current-total amount))
        (ok true)
    )
)

(define-public (claim-stake-reward (proposal-id uint))
    (let (
            (proposal (unwrap! (get-proposal proposal-id) ERR-NO-PROPOSAL))
            (stake-amount (unwrap! (get-stake proposal-id tx-sender) ERR-NO-STAKE))
            (total-stakes (get-total-stakes proposal-id))
            (reward-multiplier u120)
        )
        (asserts! (not (var-get paused)) ERR-PAUSED)
        (asserts! (is-eq (get status proposal) "approved") ERR-NOT-ACTIVE)
        (asserts! (> stake-amount u0) ERR-NO-STAKE)
        (let ((reward-amount (/ (* stake-amount reward-multiplier) u100)))
            (try! (as-contract (stx-transfer? reward-amount tx-sender tx-sender)))
            (map-delete proposal-stakes {
                proposal-id: proposal-id,
                staker: tx-sender,
            })
            (ok reward-amount)
        )
    )
)

(define-public (withdraw-failed-stake (proposal-id uint))
    (let (
            (proposal (unwrap! (get-proposal proposal-id) ERR-NO-PROPOSAL))
            (stake-amount (unwrap! (get-stake proposal-id tx-sender) ERR-NO-STAKE))
        )
        (asserts! (not (var-get paused)) ERR-PAUSED)
        (asserts! (is-eq (get status proposal) "rejected")
            ERR-STAKE-NOT-WITHDRAWABLE
        )
        (asserts! (> stake-amount u0) ERR-NO-STAKE)
        (try! (as-contract (stx-transfer? stake-amount tx-sender tx-sender)))
        (map-delete proposal-stakes {
            proposal-id: proposal-id,
            staker: tx-sender,
        })
        (ok stake-amount)
    )
)
