### vault + approve
現状
approve and spend UX

### vault + permit
技術的にも概ね解決
現実的にはあまり見ない

permitを実装しているものトークンのみ対応できる

`depositBySig(...,v,r,s)`

### vault + permit with ERC20 wrapper
技術的には解決だが、非現実的

wrapperのblacklistの危険

### vault + approvalTarget(permitAndTransferFrom)
approavalTargeに対して、一度だけapproveをする approve once, sign and spend UX
approvalTargetを経由して署名でdepositする

ほぼ全てのトークンに対応可能。(feeのあるトークンは？)
技術的にも解決

permitを実装しているトークンについてもはメリットはそれほどないか
