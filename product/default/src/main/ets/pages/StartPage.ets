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
  NewsArticle,
  NewsListAPI,
  ServerHealthAPI,
  WINDOW_WIDTH,
  WinWidth,
  LOG_TAG
} from "common"

@Entry
@ComponentV2
struct StarPage {
  uiRouter: Router = this.getUIContext().getRouter()
  @Local winWidth: number = 0
  @Local fontsize: number = 0

  async aboutToAppear(): Promise<void> {
    window.getLastWindow(this.getUIContext().getHostContext())
    const width: number = (AppStorageV2.connect(WinWidth, WINDOW_WIDTH)?.value) ?? 350
    this.winWidth = this.getUIContext().px2vp(width)
    logger.debug(`${LOG_TAG.START_PAGE}winWidth: ${this.winWidth}`)
    this.updateFontSize()
    let isServerReady: boolean = false
    setTimeout(() => {
      logger.debug(LOG_TAG.START_PAGE + '延时跳转')
      this.uiRouter.pushUrl({ url: "pages/Index", recoverable: false })
      // 为了能触发路由动画特此使用push
      logger.debug(LOG_TAG.START_PAGE + '清理启动页')
      this.uiRouter.clear()
    }, 2000)
    await ServerHealthAPI.isServerReady().then((res: boolean) => {
      logger.debug(LOG_TAG.START_PAGE + res.valueOf())
      if (res) {
        isServerReady = true
        logger.info(LOG_TAG.START_PAGE + '服务端准备就绪isServerReady=' + isServerReady)
      } else {
        isServerReady = false
        logger.info(LOG_TAG.START_PAGE + '服务端准备中isServerReady=' + isServerReady)
      }
    })
    if (isServerReady) {
      logger.debug(LOG_TAG.START_PAGE + '尝试获取全部新闻列表')
      NewsListAPI.getAllNews().then((res: NewsArticle[] | null) => {
        if (res === null) {
          logger.warn(LOG_TAG.START_PAGE + '')
        } else {
          promptAction.openToast({ message: '获取新闻列表成功', duration: 2000 })
        }
      })
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