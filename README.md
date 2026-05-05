# AnimeVoting

ブロックチェーン上に記録する改ざん不可能なアニメキャラクター投票システム。
一度投じた票はオンチェーンに刻まれ、誰も書き換えることができない。

## 技術スタック

- Solidity 0.8.20
- Foundry

## 機能

- **ホワイトリスト** `addToWhitelist(addr, weight)` - オーナーが登録したアドレスのみ投票できる
- **重み付き投票** - アドレスごとに票の重さ（weight）を設定できる。VIP投票者などに活用
- **委任** `delegate(to)` - 自分のvoteWeightをコミット前に別アドレスへ移譲できる
- **期間制限** - コミット期間・リビール期間を`block.timestamp`で管理。期間外の操作はrevert
- **コミット・リビール** - コミット期間にハッシュを提出し、リビール期間に開示して票を確定する。バンドワゴン効果を防止
- **勝者取得** `getWinner()` - 最多得票キャラクターのID・名前・票数を返す

## コミット・リビールの仕組み

```
hash = keccak256(abi.encodePacked(characterId, salt, msg.sender))
```

1. コミット期間中に `commitVote(hash)` を提出
2. リビール期間中に `revealVote(characterId, salt)` で開示・票を確定

`msg.sender` をハッシュに含めることでフロントランニングを防止している。

## セットアップ

```bash
cd src
forge install foundry-rs/forge-std
forge build
forge test
```

## デプロイ

```bash
# ローカルチェーンを起動
anvil

# デプロイ（コミット期間1日・リビール期間1日で自動設定）
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```
