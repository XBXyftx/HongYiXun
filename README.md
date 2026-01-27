# 鸿易讯 (HongYiXun)

基于 [NowInOpenHarmony](https://github.com/ifLabVibe/NowInOpenHarmony) 演进开发的 HarmonyOS 新闻资讯应用。

<img width="2048" height="2048" alt="logo" src="https://github.com/user-attachments/assets/1e5c1ecf-5f97-47f2-a746-e74d41da861b" />

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

![feb91136895df345b504aa28750b2402](https://github.com/user-attachments/assets/d5b5f553-e6bd-4f04-beb2-39a8ea85fd7f)

### 📝 笔记系统

- 图文混排笔记编辑器
- 笔记与文章关联
- 多图片上传（单篇最多10张）
- 可拖动浮动窗口编辑

![404498a99d615e0fac77955a5a44117a](https://github.com/user-attachments/assets/5663ee66-ef08-4d0c-b37e-33bd364efbc9)

![000ee7d17f5ce28fb1ecda7caccd8383](https://github.com/user-attachments/assets/d2a7c082-5bea-419a-9b42-acd9f22669ce)

![058d6c6ac144bf779531fc05910c81d2](https://github.com/user-attachments/assets/02fb1d40-071b-4d27-a4a7-0b6349a07002)

### 🖼️ 大图查看器

- 双指缩放查看
- 单指拖动浏览
- 一键保存到相册

![b38b456e9b091ab96139bde25963a43e](https://github.com/user-attachments/assets/af112dea-56ef-477f-81c9-0eb131bdc9a4)

### 阅读热力日历

![753e9c428c4bb85e0534b38cf5aa7bfa](https://github.com/user-attachments/assets/5b5e9ce4-f79a-40b9-a6f3-516d86832e0f)

![0bfb30c29d76965aee2e86a9d2a17fc5](https://github.com/user-attachments/assets/737a5a2d-37f7-4aa3-ac9d-b760df7a67fd)

### ⚙️ 个性化设置

- 字体大小调节（12-24px）
- 深色/浅色主题切换
- 笔记编辑器样式配置
- 热力图颜色自定义

## 技术栈

- **开发语言**: ArkTS
- **API 版本**: API 20
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
- HarmonyOS SDK API 20+
- 支持设备：手机、平板

## 许可证

Apache License 2.0
