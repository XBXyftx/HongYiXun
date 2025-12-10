# 鸿易讯 (HongYiXun)

基于 [NowInOpenHarmony](https://github.com/ifLabVibe/NowInOpenHarmony) 演进开发的 HarmonyOS 新闻资讯应用。

## 项目简介

鸿易讯是一款 OpenHarmony/HarmonyOS 新闻聚合应用，汇集 OpenHarmony 相关资讯，为开发者提供便捷的信息获取渠道。

## 项目演进

本项目由 [NowInOpenHarmony](https://github.com/ifLabVibe/NowInOpenHarmony) 演进而来，在原有新闻聚合功能基础上进行了大量功能扩展和架构优化。

## 功能特性

### 📰 新闻阅读

- 多数据源新闻聚合
- 文章收藏与点赞
- 浏览历史记录
- 阅读热力日历统计
- 文章搜索

### 📝 笔记系统

- 图文混排笔记编辑器
- 笔记与文章关联
- 多图片上传（单篇最多10张）
- 可拖动浮动窗口编辑

### 🖼️ 大图查看器

- 双指缩放查看
- 单指拖动浏览
- 一键保存到相册

### 🤖 AI 助手

- 集成 Coze AI 对话
- 多模型切换
- 会话历史管理

### ⚙️ 个性化设置

- 字体大小调节（12-24px）
- 深色/浅色主题切换
- 笔记编辑器样式配置
- 热力图颜色自定义

## 技术栈

- **开发语言**: ArkTS
- **API 版本**: API 18
- **UI 框架**: ArkUI
- **状态管理**: @ComponentV2 + @Local + @ObservedV2
- **数据存储**: Preferences + KV 数据库
- **网络请求**: @ohos/axios

## 项目结构

```text
├── product/default/          # 主应用入口模块
├── commons/
│   ├── common/              # 公共基础库
│   └── ai_common/           # AI 功能公共库
├── features/
│   ├── feature/             # 核心功能模块
│   └── ai_feature/          # AI 功能模块
└── AppScope/                # 应用级配置
```

## 运行环境

- DevEco Studio 5.0+
- HarmonyOS SDK API 18+
- 支持设备：手机、平板

## 开发说明

1. 克隆项目

   ```bash
   git clone <repository-url>
   ```

2. 使用 DevEco Studio 打开项目

3. 同步依赖

   ```bash
   ohpm install
   ```

4. 运行项目

## 许可证

Apache License 2.0
