# M-Team API 使用指南

## API 接口信息

- **基础 URL**: `https://api.m-team.cc`
- **认证方式**: 通过 `x-api-key` 请求头传递 API Key

### 1. 种子搜索接口
- **接口路径**: `/api/torrent/search`
- **请求方法**: `POST`
- **Content-Type**: `application/json`

### 2. 获取下载链接接口
- **接口路径**: `/api/torrent/genDlToken`
- **请求方法**: `POST`
- **Content-Type**: `application/x-www-form-urlencoded`
- **功能说明**: 根据种子 ID 生成种子下载链接

## 种子搜索接口详情

### 搜索请求参数

```typescript
interface SearchParams {
  mode: string;           // 搜索模式，如 "movie"
  visible: number;        // 可见性，通常为 1
  keyword: string;        // 搜索关键词
  categories: string[];   // 分类数组，可为空
  pageNumber: number;     // 页码，从 1 开始
  pageSize: number;       // 每页数量，最大 100
}
```

### 搜索请求示例

```javascript
import ky from "ky";

const API_KEY = "your-api-key-here";

const response = await ky.post("https://api.m-team.cc/api/torrent/search", {
  headers: {
    "x-api-key": API_KEY,
    "Content-Type": "application/json"
  },
  json: {
    mode: "movie",
    visible: 1,
    keyword: "哪吒",
    categories: [],
    pageNumber: 1,
    pageSize: 100
  }
});

const data = await response.json();
```

### 搜索响应类型定义 (TypeScript)

```typescript
// 种子状态信息
interface TorrentStatus {
  id: string;
  createdDate: string;
  lastModifiedDate: string;
  pickType: string;
  toppingLevel: string;
  toppingEndTime: string | null;
  discount: string;                // 如 "PERCENT_50" 表示 50% 优惠
  discountEndTime: string | null;
  timesCompleted: string;          // 完成次数
  comments: string;                 // 评论数
  lastAction: string;
  lastSeederAction: string;
  views: string;                    // 浏览次数
  hits: string;
  support: string;
  oppose: string;
  status: string;                   // 如 "NORMAL"
  seeders: string;                  // 种子数
  leechers: string;                 // 下载者数
  banned: boolean;
  visible: boolean;
  promotionRule: string | null;
  mallSingleFree: string | null;
}

// 种子信息
interface Torrent {
  id: string;
  createdDate: string;
  lastModifiedDate: string;
  name: string;                     // 种子名称
  smallDescr: string;               // 简短描述
  imdb: string;                     // IMDB 链接
  imdbRating: string;               // IMDB 评分
  douban: string;                   // 豆瓣链接
  doubanRating: string;             // 豆瓣评分
  dmmCode: string;
  author: string | null;
  category: string;                 // 分类 ID
  source: string | null;
  medium: string | null;
  standard: string;                 // 标准，如 "6" 表示 4K
  videoCodec: string;               // 视频编码
  audioCodec: string;               // 音频编码
  team: string | null;
  processing: string | null;
  countries: string[];              // 国家/地区
  numfiles: string;                 // 文件数量
  size: string;                     // 文件大小（字节）
  labels: string;
  labelsNew: string[];              // 标签数组，如 ["中字", "4k", "中配", "hdr10"]
  msUp: string;
  anonymous: boolean;
  infoHash: string | null;
  status: TorrentStatus;            // 种子状态
  dmmInfo: string | null;
  editedBy: string | null;
  editDate: string;
  collection: boolean;
  inRss: boolean;
  canVote: boolean;
  imageList: string[];              // 图片链接数组
  resetBox: string | null;
}

// 分页信息
interface PageData {
  pageNumber: string;
  pageSize: string;
  total: string;                    // 总记录数
  totalPages: string;               // 总页数
  data: Torrent[];                  // 种子数组
}

// API 响应
interface ApiResponse {
  code: string;                     // 响应码，"0" 表示成功
  message: string;                  // 响应消息，如 "SUCCESS"
  data: PageData;                   // 分页数据
}
```

## 获取下载链接接口详情

### 请求参数

```typescript
interface GenDlTokenParams {
  id: number | string;  // 种子 ID
}
```

### 请求示例

```javascript
import ky from "ky";

const API_KEY = "your-api-key-here";

// 获取种子下载链接
async function getTorrentDownloadUrl(torrentId) {
  const response = await ky.post("https://api.m-team.cc/api/torrent/genDlToken", {
    headers: {
      "x-api-key": API_KEY,
      "Content-Type": "application/x-www-form-urlencoded"
    },
    body: new URLSearchParams({
      id: torrentId.toString()
    }),
    timeout: 30000
  });

  const data = await response.json();
  return data;
}

// 使用示例
getTorrentDownloadUrl(1020011).then(result => {
  if (result.code === "0") {
    console.log("下载链接:", result.data);
  }
});
```

### 响应格式

```typescript
interface GenDlTokenResponse {
  code: string;     // 响应码，"0" 表示成功
  message: string;  // 响应消息，如 "SUCCESS"
  data: string;     // 种子下载链接 URL
}
```

### 响应示例

```json
{
  "code": "0",
  "message": "SUCCESS",
  "data": "https://api.m-team.cc/api/rss/dlv2?sign=bfd24547493b38eb8fd32ef5fe5fea2a&t=1755705305&tid=1020011&uid=283090"
}
```

响应中的 `data` 字段即为种子文件的下载地址，可以直接使用该 URL 下载种子文件。

## 完整使用示例

```typescript
import ky from "ky";

const API_KEY = "YOUR_API_KEY_HERE";

async function searchTorrents(keyword: string): Promise<ApiResponse> {
  const searchParams: SearchParams = {
    mode: "movie",
    visible: 1,
    keyword,
    categories: [],
    pageNumber: 1,
    pageSize: 100
  };

  const response = await ky.post("https://api.m-team.cc/api/torrent/search", {
    headers: {
      "x-api-key": API_KEY,
      "Content-Type": "application/json"
    },
    json: searchParams,
    timeout: 30000
  });

  const data: ApiResponse = await response.json();
  
  if (data.code === "0") {
    console.log(`找到 ${data.data.total} 个结果`);
    
    // 显示前 3 个结果
    data.data.data.slice(0, 3).forEach((torrent, index) => {
      console.log(`${index + 1}. ${torrent.name}`);
      console.log(`   大小: ${(parseInt(torrent.size) / 1024 / 1024 / 1024).toFixed(2)} GB`);
      console.log(`   种子: ${torrent.status.seeders} | 下载: ${torrent.status.leechers}`);
      console.log(`   标签: ${torrent.labelsNew.join(", ")}`);
    });
  }
  
  return data;
}

// 使用示例：搜索种子并获取下载链接
async function searchAndDownload(keyword: string) {
  try {
    // 1. 搜索种子
    const searchResult = await searchTorrents(keyword);
    
    if (searchResult.code === "0" && searchResult.data.data.length > 0) {
      const firstTorrent = searchResult.data.data[0];
      console.log(`找到种子: ${firstTorrent.name}`);
      
      // 2. 获取下载链接
      const dlResponse = await ky.post("https://api.m-team.cc/api/torrent/genDlToken", {
        headers: {
          "x-api-key": API_KEY,
          "Content-Type": "application/x-www-form-urlencoded"
        },
        body: new URLSearchParams({
          id: firstTorrent.id
        })
      });
      
      const dlData: GenDlTokenResponse = await dlResponse.json();
      
      if (dlData.code === "0") {
        console.log(`下载链接: ${dlData.data}`);
        // 可以使用返回的 URL 下载种子文件
      }
    }
  } catch (error) {
    console.error("操作失败:", error);
  }
}

// 执行示例
searchAndDownload("哪吒");
```

## 注意事项

1. **API Key 安全**: 不要将 API Key 提交到公开的代码仓库
2. **请求频率**: 建议在连续请求之间添加延迟，避免请求过于频繁
3. **错误处理**: 始终检查响应的 `code` 字段，"0" 表示成功
4. **分页限制**: `pageSize` 最大值通常为 100
5. **标签说明**: `labelsNew` 数组包含了种子的各种标签，如画质、字幕、音轨等信息

## 常见标签含义

- `中字`: 包含中文字幕
- `4k`: 4K 分辨率
- `中配`: 包含中文配音
- `hdr10`: 支持 HDR10
- `PERCENT_50`: 50% 下载优惠（上传量计算）