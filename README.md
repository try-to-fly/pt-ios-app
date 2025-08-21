# M-Team PT iOS App

一个现代化的 M-Team PT 移动端应用，采用 SwiftUI 和 MVVM 架构构建。

## ✨ 特性

- 🔍 **智能搜索**: 支持关键词搜索和分类筛选
- 📱 **现代 UI**: 采用 iOS 设计规范，支持深色模式
- ⚡ **高性能**: 智能缓存和无限滚动加载
- 🔒 **安全存储**: 使用 Keychain 安全存储 API 密钥
- 🎨 **主题定制**: 多种主题色彩可选
- 📲 **无缝体验**: 流畅的动画和手势操作

## 🏗️ 技术架构

### 核心技术栈
- **SwiftUI**: 声明式 UI 框架
- **MVVM**: 清晰的架构分层
- **Combine**: 响应式编程
- **async/await**: 现代异步编程

### 项目结构
```
MTeamPT/
├── App/                    # 应用入口和配置
├── Models/                 # 数据模型
├── Services/              # 网络服务和 API 客户端
├── ViewModels/            # MVVM 视图模型
├── Views/                 # SwiftUI 界面
│   ├── Search/           # 搜索界面
│   ├── Detail/           # 详情页面
│   ├── Settings/         # 设置页面
│   └── Components/       # 通用组件
├── Utils/                 # 工具类
├── Resources/            # 资源文件
└── Extensions/           # 扩展
```

## 🚀 功能介绍

### 搜索功能
- 实时搜索建议
- 分类筛选（电影、电视剧、音乐等）
- 无限滚动加载
- 智能缓存机制

### 种子详情
- 完整的种子信息展示
- 健康度可视化指示
- 优惠标签显示
- 一键获取下载链接

### 用户设置
- API 密钥管理
- 主题色彩定制
- 缓存管理
- 深色模式支持

## 📋 系统要求

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

## 🛠️ 开发设置

1. 克隆项目
```bash
git clone https://github.com/mteam/ios-app.git
cd ios-app
```

2. 打开 Xcode 项目
```bash
open MTeamPT.xcodeproj
```

3. 配置开发者账户和证书

4. 构建并运行

## 🔧 配置说明

### API 密钥
首次启动应用时，需要配置 M-Team API 密钥：
1. 登录 M-Team 网站
2. 进入控制面板 → API 设置
3. 生成或复制 API 密钥
4. 在应用中输入密钥

### 网络安全
应用已配置 App Transport Security (ATS)，允许与 M-Team API 的安全通信。

## 🎨 UI 设计特色

### 现代化界面
- 毛玻璃效果（Glassmorphism）
- 动态渐变背景
- 流畅的过渡动画
- 3D 触感按钮

### 用户体验
- 触觉反馈
- 骨架屏加载
- 下拉刷新
- 智能搜索建议

## 🔒 安全特性

- **Keychain 存储**: API 密钥安全存储在系统 Keychain 中
- **HTTPS 通信**: 所有网络请求使用 HTTPS 加密
- **输入验证**: 防止恶意输入和 XSS 攻击

## 📊 性能优化

### 缓存策略
- **内存缓存**: 搜索结果和图片内存缓存
- **磁盘缓存**: 持久化缓存，提升启动速度
- **智能清理**: 自动清理过期缓存

### 网络优化
- **请求重试**: 网络错误自动重试
- **并发控制**: 限制同时进行的网络请求
- **超时控制**: 合理的请求超时设置

## 🧪 测试

项目包含完整的单元测试和 UI 测试：

```bash
# 运行单元测试
xcodebuild test -scheme MTeamPT -destination 'platform=iOS Simulator,name=iPhone 14'

# 运行 UI 测试
xcodebuild test -scheme MTeamPTUITests -destination 'platform=iOS Simulator,name=iPhone 14'
```

## 📝 版本历史

### v1.0.0
- 初始版本发布
- 基础搜索和下载功能
- 现代化 UI 设计
- 安全存储和缓存

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 📞 联系我们

- 项目链接: [https://github.com/mteam/ios-app](https://github.com/mteam/ios-app)
- 问题反馈: [Issues](https://github.com/mteam/ios-app/issues)
- 邮箱: support@mteam.app

## 🙏 致谢

感谢 M-Team 社区的支持和反馈，让这个项目得以完善。

---

**注意**: 本应用仅供学习和研究使用，请遵守相关法律法规和网站使用条款。