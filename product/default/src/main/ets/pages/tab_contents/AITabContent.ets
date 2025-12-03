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

import { AppStorageV2 } from '@kit.ArkUI'
import {
  AIModelType,
  AI_LOG_TAG,
  aiLogger
} from 'ai_common'
import { APP_STORAGE_KEYS, NAV_DESTS } from 'common'
import { AIChatPageParam } from '../nav_pages/AIChatPage'

/**
 * AI Tab入口页面
 * 
 * 显示模型选择器，点击后导航到AI对话页面
 */
@ComponentV2
export struct AITabContent {
  /** 导航栈 */
  @Local private navPathStuck: NavPathStack = new NavPathStack()

  aboutToAppear(): void {
    // 连接导航栈
    const navStack = AppStorageV2.connect(
      NavPathStack,
      APP_STORAGE_KEYS.NAV_PATH_STUCK,
      () => new NavPathStack()
    )
    if (navStack) {
      this.navPathStuck = navStack
    }
  }


  /**
   * 处理模型选择并导航到对话页面
   */
  private handleModelSelected(modelType: AIModelType): void {
    aiLogger.info(`${AI_LOG_TAG.AI_PAGE}选择模型并导航: ${modelType}`)
    
    // 导航到AI对话页面，模型类型通过参数传递
    // 新会话将在AIChatPage的onReady中创建
    const param: AIChatPageParam = { modelType: modelType }
    this.navPathStuck.replacePath({
      name: NAV_DESTS.AI_CHAT,
      param: param
    }, {
      animated: true
    })
  }

  /**
   * 模型选项卡构建器
   */
  @Builder
  modelOptionBuilder(
    title: string,
    description: string,
    iconName: string,
    modelType: AIModelType,
    sharedId: string
  ) {
    Row() {
      Image($rawfile(iconName))
        .width(56)
        .height(56)
        .objectFit(ImageFit.Contain)
        .margin({ right: 16 })

      Column() {
        Text(title)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        
        Text(description)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Image($rawfile('arrow_right.svg'))
        .width(20)
        .height(20)
        .fillColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(20)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(16)
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
    .geometryTransition(sharedId, { follow: true })
    .onClick(() => {
      this.handleModelSelected(modelType)
    })
  }

  build() {
    Column() {
      // 顶部标题
      Row() {
        Text('鸿小易')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .height(60)
      .padding({ left: 20, right: 20 })
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)

      // 欢迎语
      Column() {
        Text('你好，我是鸿小易')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        
        Text('选择一种对话模式开始聊天')
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 8 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 40, bottom: 40 })
      .alignItems(HorizontalAlign.Start)

      // 模型选择卡片
      Column({ space: 16 }) {
        // 快速回答
        this.modelOptionBuilder(
          '快速回答',
          '响应迅速，适合简单问题',
          'ai_quick.svg',
          AIModelType.QUICK_ANSWER,
          'ai_chat_quick'
        )

        // 深度思考
        this.modelOptionBuilder(
          '深度思考',
          '深度搜索分析，适合复杂问题',
          'ai_deep.svg',
          AIModelType.DEEP_THINKING,
          'ai_chat_deep'
        )
      }
      .width('100%')
      .padding({ left: 20, right: 20 })

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}
