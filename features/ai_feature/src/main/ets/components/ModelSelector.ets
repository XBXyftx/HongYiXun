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
  AI_STORAGE_KEYS,
  CurrentModelTypeState,
  aiLogger,
  AI_LOG_TAG
} from 'ai_common'

/**
 * AI模型选择器组件
 * 
 * 用于选择快速回答或深度思考模式
 */
@ComponentV2
export struct ModelSelector {
  /** 模型选择回调 */
  @Param onModelSelectedCallback: (modelType: AIModelType) => void = () => {}
  
  @Local private selectedModel: AIModelType = AIModelType.NOT_SELECTED

  /**
   * 处理模型选择
   */
  private handleSelectModel(modelType: AIModelType): void {
    aiLogger.info(`${AI_LOG_TAG.AI_PAGE}ModelSelector - 点击选择模型: ${modelType}, 当前选中: ${this.selectedModel}`)
    
    this.selectedModel = modelType
    
    aiLogger.info(`${AI_LOG_TAG.AI_PAGE}ModelSelector - 更新后选中: ${this.selectedModel}`)
    
    // 更新全局状态
    const modelState = AppStorageV2.connect(
      CurrentModelTypeState,
      AI_STORAGE_KEYS.CURRENT_MODEL_TYPE,
      () => new CurrentModelTypeState()
    )
    if (modelState !== undefined) {
      modelState.modelType = modelType
      aiLogger.info(`${AI_LOG_TAG.AI_PAGE}ModelSelector - 全局状态已更新: ${modelState.modelType}`)
    }
    
    this.onModelSelectedCallback(modelType)
  }

  build() {
    Column({ space: 20 }) {
      // 标题
      Text('选择对话模式')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .margin({ bottom: 16 })

      // 快速回答选项
      Row() {
        Image($rawfile('ai_quick.svg'))
          .width(48)
          .height(48)
          .objectFit(ImageFit.Contain)
          .margin({ right: 16 })

        Column() {
          Text('快速回答')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          
          Text('响应迅速，适合简单问题')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        if (this.selectedModel === AIModelType.QUICK_ANSWER) {
          Image($rawfile('check_circle.svg'))
            .width(24)
            .height(24)
            .fillColor($r('app.color.brand'))
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.selectedModel === AIModelType.QUICK_ANSWER ? $r('app.color.brand_light') : $r('app.color.card_background'))
      .borderRadius(12)
      .border({
        width: this.selectedModel === AIModelType.QUICK_ANSWER ? 2 : 1,
        color: this.selectedModel === AIModelType.QUICK_ANSWER ? $r('app.color.brand') : $r('app.color.border')
      })
      .shadow(this.selectedModel === AIModelType.QUICK_ANSWER ? {
        radius: 12,
        color: $r('app.color.brand_shadow'),
        offsetX: 0,
        offsetY: 4
      } : {
        radius: 0,
        color: Color.Transparent,
        offsetX: 0,
        offsetY: 0
      })
      .scale({ x: this.selectedModel === AIModelType.QUICK_ANSWER ? 1.02 : 1, y: this.selectedModel === AIModelType.QUICK_ANSWER ? 1.02 : 1 })
      .onClick(() => {
        this.handleSelectModel(AIModelType.QUICK_ANSWER)
      })
      .animation({
        duration: 200,
        curve: Curve.EaseOut
      })

      // 深度思考选项
      Row() {
        Image($rawfile('ai_deep.svg'))
          .width(48)
          .height(48)
          .objectFit(ImageFit.Contain)
          .margin({ right: 16 })

        Column() {
          Text('深度思考')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          
          Text('深度搜索分析，适合复杂问题')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        if (this.selectedModel === AIModelType.DEEP_THINKING) {
          Image($rawfile('check_circle.svg'))
            .width(24)
            .height(24)
            .fillColor($r('app.color.brand'))
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.selectedModel === AIModelType.DEEP_THINKING ? $r('app.color.brand_light') : $r('app.color.card_background'))
      .borderRadius(12)
      .border({
        width: this.selectedModel === AIModelType.DEEP_THINKING ? 2 : 1,
        color: this.selectedModel === AIModelType.DEEP_THINKING ? $r('app.color.brand') : $r('app.color.border')
      })
      .shadow(this.selectedModel === AIModelType.DEEP_THINKING ? {
        radius: 12,
        color: $r('app.color.brand_shadow'),
        offsetX: 0,
        offsetY: 4
      } : {
        radius: 0,
        color: Color.Transparent,
        offsetX: 0,
        offsetY: 0
      })
      .scale({ x: this.selectedModel === AIModelType.DEEP_THINKING ? 1.02 : 1, y: this.selectedModel === AIModelType.DEEP_THINKING ? 1.02 : 1 })
      .onClick(() => {
        this.handleSelectModel(AIModelType.DEEP_THINKING)
      })
      .animation({
        duration: 200,
        curve: Curve.EaseOut
      })
    }
    .width('100%')
    .padding({ left: 20, right: 20 })
  }
}
