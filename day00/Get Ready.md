## building concensus
### Trust Mechanisms: Three layers of trust
- Trusted: Trust gained through official licenses or permissions, such as banks or payment licenses.
- Trustworthy: Trust based on market consensus and security certifications, like some SaaS services.
- Trustless: Trust established through cryptography and mathematical constructs, independent of institutional reputation; the trust model represented by blockchain technology.

These three layers reflect the evolution of trust mechanisms from traditional to decentralized, highlighting the ongoing transformation of financial trust systems through technology. The core advantage of blockchain technology lies in using mathematical and cryptographic algorithms to build a trust mechanism that does not rely on traditional intermediaries.

### How to build a trust mechanism
#### Immutability — Code is Law — Consensus Algorithms (PoS):
Immutability means data, once recorded on a blockchain, cannot be altered. “Code is Law” expresses the idea that protocol rules encoded in software govern behavior. Consensus algorithms (such as Proof of Stake, PoS) determine how participants agree on the next block. Note Bitcoin specifically uses Proof of Work (PoW), not PoS. Many other blockchains (e.g., Ethereum post‑Merge) use PoS.

- Merkle Tree:
Data integrity is verified using a tree-structured hash. Leaf data are hashed, then combined pairwise and hashed recursively until a single root hash is produced. For two leaves A and B, a simple step is $\text{hash}_{AB} = H(H(A)\,\Vert\,H(B))$, and this process repeats up the tree to yield the Merkle root. This structure optimizes blockchain data storage and verification efficiency.

- Hash Functions:
Algorithms like SHA‑256 are used to compute block hashes and ensure data integrity. In Bitcoin, the block header hash must satisfy the mining target condition $H(\text{block header}) < \text{target}$. Bitcoin specifically applies double SHA‑256 to the block header (i.e., SHA‑256 of SHA‑256(header)) when evaluating the proof‑of‑work condition. Bitcoin periodically adjusts the target (every 2,016 blocks) so the network’s average block time remains ~10 minutes; lowering the target increases difficulty.

 #### Self-Sovereign — Signatures — Cryptography Basics:
Self-sovereign identity emphasizes user-controlled keys and signatures rather than reliance on centralized authorities.

- Elliptic Curve Digital Signature Algorithm (ECDSA):
Bitcoin uses the secp256k1 curve. Its short Weierstrass form is y^2 = x^3 + 7 over a finite field. A private key generates a public key via elliptic curve scalar multiplication (point multiplication), and transaction signatures are verified using ECDSA, making forgery computationally infeasible under current assumptions.
 
- Mining Incentives — Block Rewards (Halving):
Bitcoin’s block subsidy starts at 50 BTC and halves every 210,000 blocks (roughly every four years), which constrains total issuance to about 21 million BTC. A clearer reward expression is:
$\text{reward}(h) = 50 \times 2^{-\left\lfloor \frac{h}{210{,}000} \right\rfloor}$
where $h$ is the block height and $\left\lfloor \cdot \right\rfloor$ ensures the reward steps down discretely at each halving.

## Basics
- DEX：
    - UniSwap:https://uniswap.org/
    - SushiSwap:https://sushi.com/
    - dYdX:https://dydx.exchange/
    - PancakeSwap:https://pancakeswap.finance/
- Gamefi: play to earn
  - TheSandbox:https://www.sandbox.game/en/
  - Decentraland:https://decentraland.org/
  - Axie Infinity:https://axieinfinity.com/
- NFT（Non-fungible token）

        Tokens are fungible assets, meaning each unit (like a coin) has the same value as any other unit; NFTs are non-fungible assets, currently used mainly for digital art and Web3 profile images. Fungible tokens are typically implemented with the ERC‑20 standard, while NFTs are commonly implemented with ERC‑721 or ERC‑1155. ERC‑721 is the canonical non‑fungible token standard on Ethereum, and ERC‑1155 is a multi‑token standard supporting all fungible, semi‑fungible, and non‑fungible types in one contract. 
    NFT trading platform: Opensea:https://opensea.io/
    
    popular NFT projects: crypto punk, Bored Ape Yacht Club, Doodles, Cool cats, Azuki, crypto coven

- DAO（decentralized autonomous organization)
  
        Unlike traditional companies, you can work for more than one DAO at the same time. DAOs advocate “building together and sharing the upside.” Your contributions in a DAO can be quantified as on‑chain assets such as tokens, POAPs (Proof of Attendance Protocol badges), and NFTs. In simple terms: in a company, you work for a boss who owns the firm’s assets and equity; in a DAO, there’s no boss—only contributors. If members believe an early participant is harming the DAO’s interests, they can vote to remove that person. DAOs can issue their own governance tokens and NFTs. A successful DAO invariably needs a well‑designed token incentive model, with clear rewards and penalties, to keep operations efficient while protecting member interests.

    popular DAO projects: FWB, Bankless

## Reading Materials
- Bitcoin: A Peer-to-Peer Electronic Cash System by Satoshi Nakamoto
- The Little Bitcoin Book: Why Bitcoin Matters for Your Freedom, Finances, and Future by Lily Liu and Timi Ajiboye
- ahr999囤币指南
- https://ethereum.org/en/whitepaper/
- How to Defi: Beginner
- 《a16z合伙人对话Coinlist创始人Naval：WEB3.0的奇迹》https://mp.weixin.qq.com/s/BPpcpWbdRLslGcB4w6e2LQ
- 《我们正处在区块链行业历史的前三分钟，这个时代意味着什么》https://mp.weixin.qq.com/s/JEG2okBIHZBzCV3nfu1Rlg
- 《浅谈我所理解的NFT和Metaverse》https://mp.weixin.qq.com/s/H5hz11MZC7zEuuaMSTQEiA
- 《DeFi之道访谈：如何参与Web3？哪些细分赛道值得关注？》https://mp.weixin.qq.com/s/7mKiZVM7mSWEGFqOahfedg
- 《a16z合伙人对话Paradigm合伙人：我们第一次把经济系统内嵌到了互联网里》https://www.techflow520.com/news/400
- 加密思潮编年史:https://foresightnews.pro/article/detail/961
- ​大白话聊 Web3——终将到来的时代，会如我们所想吗？（Sarah & 王建硕）https://www.xiaoyuzhoufm.com/episode/62d93b1cfa15142e17251e05?s=eyJ1IjogIjVmYzM2ZGRlZTBmNWU3MjNiYjg2ODE3YSJ9
- 16z合伙人对话Coinlist创始人Naval：WEB3.0的奇迹 https://tim.blog/2021/10/28/chris-dixon-naval-ravikant/ 
- https://www.coindesk.com/podcasts/women-who-web3/artistry-and-the-entrepreneurial-spirit-with-randi-zuckerberg-and-debbie-soon/
- 可视化解释btc https://www.bilibili.com/video/BV11x411i72w/ & https://youtu.be/5hgdekVZb3A?si=OA7A-Wuq61QHWVO6 
- 0基础理解密码学 https://www.bilibili.com/video/BV1yx411i7BX/
- 代币经济学 101 基于博弈论的 Web 3.0 与 Web 2.0 浅析 https://mp.weixin.qq.com/s/2_EfySfAgLz2E5CGaHE12g
- 放学以后After School第18期播客
- Tulipomania : the story of the world's most coveted flower and the extraordinary passions it aroused by Mike Dash
- Dovey & Daniel 对话 https://mp.weixin.qq.com/s/q3M7vUK7yeHafNHYdy7v-A
- 无人知晓 podcast E13 Zara 对话孟岩：最好的投资，是投资自己
- 致所有人 - 今天如何快速角色化进入 Web3: https://mirror.xyz/0xkookoo.eth/BF7jfmieDL4AxzQKRuyCF0MzZ7mmmrVlCuF5CRoAbAk
- 主权个人
- 技术革命与金融资本
- 失控
- 货币未来：从金本位到区块链
- 美第奇银行的兴衰
- Read Write Own by Chris Dixon
- the network state https://thenetworkstate.com/ 
- 从技术到应用：普通人的Web3学习手册 （微信读书）

## Info digest
微信公众号: 链闻ChainNews, 巴比特资讯, 元宇宙之道, 区块律动BlockBeats, 深潮TechFlow, Empower Labs, 文森特二, 德拉图Delato, 不懂经, 理想屯,Rebase社区, 慢雾科技, 登链社区, 白话区块链, 浅黑科技, Uncommons, BuidlerDao, 孟岩的区块链思考

推特：(https://twitter.com/luyun11184053), Coopahtroopa.eth, cdixon.eth, 6529, MapleLeafCap, CM | 陈默Bitouq, k.mirror.xyz, Chao, Vincent Niu, Panda, guoyu.eth, dao4ever.eth

微博: 张潇雨老师:@VicodinXYZ, 中二怪, 胡翌霖, 十一地主, Alpha小屏, defi阿飞

中文播客（小宇宙app）: Web3随意门, CSS|探索Crypto的精彩世界, What the Meta, Unchained, HODlong后浪, Web3 101, Buidler Talk | Web3 对谈, Traders’ Talk, 文理两开花, 墙裂谈

Crypto VC: a16z, 红杉资本, Paridigm

## open courses
- Patrick Collins Blockchain Developer, Solidity, Foundry Full Course 2023 https://www.youtube.com/playlist?list=PL4Rj_WH6yLgWe7TxankiqkrkVKXIwOP42
- Patrick Collins Learn Solidity Smart Contract Development | Full 2024 Cyfrin… https://www.youtube.com/watch?v=-1GB6m39-rM 
- Buidler DAO 比特币系统本质探索｜区块链基础系列课 https://www.youtube.com/watch?v=cEG1DvlbF_0&list=PLOGGvFbKWOAQJWncBsun4a1ln5ScTzJu2
- Dapp University Free Blockchain Development Courses https://www.youtube.com/playlist?list=PLS5SEs8ZftgUNcUVXtn2KXiE1Ui9B5UrY
- MIT OpenCourseWare Blockchain and Money https://www.youtube.com/watch?v=EH6vE97qIP4

```html
<details>
每周完成学习，记录/总结并分享到社交媒体（X）。
    - 每周Github 7天学习的代码
    - 每周推特打卡, 每周日20:00为截止时间
参与周日答疑和分享会。
    - 20:00进场截图*1, 22:00结束会议截图
    - 考勤信息登记 https://docs.qq.com/sheet/DZVptVUtmV01rT2Za
提交Demo项目
</details>
```