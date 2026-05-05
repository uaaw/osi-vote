# AnimeVoting

ブロックチェーン上に記録する改ざん不可能なアニメキャラクター投票システム。
一度投じた票はオンチェーンに刻まれ、誰も書き換えることができない。

## 技術スタック

- Solidity 0.8.20
- Foundry

## 機能

- **キャラクター登録** `addCharacter(name)` - オーナーのみ投票候補を追加できる
- **投票** `vote(characterId)` - 一アドレス一票。投票後の変更は不可
- **投票開閉** `setVotingOpen(bool)` - オーナーが投票期間をコントロールできる
- **一覧取得** `getCharacters()` - 全キャラクターと得票数を返す
- **勝者取得** `getWinner()` - 最多得票キャラクターのID・名前・票数を返す

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

# デプロイ（初期キャラクター5体が自動登録される）
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```
