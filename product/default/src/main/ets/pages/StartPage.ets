/**
 * Copyright (c) 2025 XBXyftx
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { AppStorageV2, promptAction, Router, window } from "@kit.ArkUI"
import {
  logger,
  ServerHealthAPI,
  APP_STORAGE_KEYS,
  WinWidth,
  LOG_TAG
} from "common"
import { newsManager } from "feature"

@Entry
@ComponentV2
struct StarPage {
  uiRouter: Router = this.getUIContext().getRouter()
  @Local winWidth: number = 0
  @Local fontsize: number = 0

  /**
   * 页面即将显示生命周期
   * 
   * @remarks
   * 数据加载策略（分两阶段）：
   * 
   * **阶段 1 - 首屏快速加载（同步等待）**
   * - 加载最新 10 条新闻
   * - 快速显示首屏内容
   * - 提升用户首次体验
   * 
   * **阶段 2 - 后台分页加载（异步执行）**
   * - 在后台分页加载剩余新闻
   * - 每页 50 条，逐页加载
   * - 不阻塞页面跳转
   * - 用户在主页即可看到加载进度
   */
  async aboutToAppear(): Promise<void> {
    window.getLastWindow(this.getUIContext().getHostContext())
    const width: number = (AppStorageV2.connect(WinWidth, APP_STORAGE_KEYS.WINDOW_WIDTH)?.value) ?? 350
    this.winWidth = this.getUIContext().px2vp(width)
    logger.debug(`${LOG_TAG.START_PAGE}winWidth: ${this.winWidth}`)
    this.updateFontSize()

    // 设置 2 秒后跳转到主页
    setTimeout(() => {
      logger.debug(LOG_TAG.START_PAGE + '延时跳转')
      this.uiRouter.pushUrl({ url: "pages/Index", recoverable: false })
      logger.debug(LOG_TAG.START_PAGE + '清理启动页')
      this.uiRouter.clear()
    }, 2000)

    // 检查服务端状态
    const isServerReady = await ServerHealthAPI.isServerReady()
    logger.debug(`${LOG_TAG.START_PAGE}服务端状态: ${isServerReady}`)

    if (!isServerReady) {
      logger.info(`${LOG_TAG.START_PAGE}服务端未就绪，跳过数据加载`)
      promptAction.openToast({ message: '服务器未就绪，将显示缓存数据', duration: 2000 })
      return
    }

    logger.info(`${LOG_TAG.START_PAGE}服务端就绪，开始分阶段数据加载`)

    try {
      // ========== 阶段 1：首屏快速加载（同步等待）==========
      logger.info(`${LOG_TAG.START_PAGE}[阶段 1] 开始快速加载最新 10 条新闻...`)
      const latestLoadSuccess = await newsManager.loadLatestNewsToDB(10)

      if (latestLoadSuccess) {
        logger.info(`${LOG_TAG.START_PAGE}[阶段 1] ✓ 首屏数据加载成功`)
        promptAction.openToast({ message: '最新新闻已加载', duration: 1500 })
      } else {
        logger.warn(`${LOG_TAG.START_PAGE}[阶段 1] ✗ 首屏数据加载失败，将显示缓存数据`)
        promptAction.openToast({ message: '加载失败，显示缓存数据', duration: 1500 })
      }

      // ========== 阶段 2：后台分页加载（异步执行）==========
      logger.info(`${LOG_TAG.START_PAGE}[阶段 2] 开始后台分页加载所有新闻...`)
      
      // 异步执行分页加载，不阻塞页面跳转
      newsManager.loadNewsIncrementally(50, (loadedCount: number) => {
        logger.info(`${LOG_TAG.START_PAGE}[阶段 2] 进度更新: 已加载 ${loadedCount} 条新闻`)
      }).then((success: boolean) => {
        if (success) {
          logger.info(`${LOG_TAG.START_PAGE}[阶段 2] ✓ 所有新闻加载完成`)
          promptAction.openToast({ message: '所有新闻加载完成', duration: 2000 })
        } else {
          logger.warn(`${LOG_TAG.START_PAGE}[阶段 2] ✗ 分页加载部分失败`)
          promptAction.openToast({ message: '部分新闻加载失败', duration: 2000 })
        }
      }).catch((error: Error) => {
        logger.error(`${LOG_TAG.START_PAGE}[阶段 2] 分页加载异常: ${error.message}`)
      })

      logger.info(`${LOG_TAG.START_PAGE}后台加载已启动，不阻塞页面跳转`)

    } catch (error) {
      let err = error as Error
      logger.error(`${LOG_TAG.START_PAGE}数据加载异常: ${err.message}`)
      promptAction.openToast({ message: '数据加载失败', duration: 2000 })
    }
  }

  pageTransition() {
    PageTransitionExit({ type: RouteType.None, duration: 200, curve: Curve.EaseInOut })
      .slide(SlideEffect.Left)
  }

  updateFontSize() {
    const num = 16
    this.fontsize = (Math.floor((this.winWidth) / num)) + 20
  }


  build() {

    Column() {
      if (this.winWidth <= 840) {
        Image($r('app.media.logo'))
          .width('40%')
          .margin({ bottom: 100 })
          .shadow({
            color: Color.White,
            radius: 50
          })
          .borderRadius(35)
      } else {
        Image($r('app.media.logo'))
          .width('20%')
          .margin({ bottom: 100 })
          .shadow({
            color: Color.White,
            radius: 50
          })
          .borderRadius(70)
      }
      Text('鸿易讯')
        .fontSize(this.fontsize)
        .fontColor('#ff00be53')
        .fontWeight(700)
    }
    .expandSafeArea()
    .backgroundColor(Color.Black)
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')

  }
}