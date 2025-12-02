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
  IModelOptionParams,
  ModelOptionParams
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

  build() {
    Column({ space: 20 }) {
      // 标题
      Text('选择对话模式')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .margin({ bottom: 16 })

      // 快速回答选项
      this.ModelOptionCard(new ModelOptionParams(
        '快速回答',
        '响应迅速，适合简单问题',
        $rawfile('ai_quick.svg'),
        AIModelType.QUICK_ANSWER,
        this.selectedModel === AIModelType.QUICK_ANSWER
      ))

      // 深度思考选项
      this.ModelOptionCard(new ModelOptionParams(
        '深度思考',
        '深度搜索分析，适合复杂问题',
        $rawfile('ai_deep.svg'),
        AIModelType.DEEP_THINKING,
        this.selectedModel === AIModelType.DEEP_THINKING
      ))
    }
    .width('100%')
    .padding({ left: 20, right: 20 })
  }

  @Builder
  ModelOptionCard(options: IModelOptionParams) {
    Row() {
      // 图标
      Image(options.icon)
        .width(48)
        .height(48)
        .objectFit(ImageFit.Contain)
        .margin({ right: 16 })

      // 文字内容
      Column() {
        Text(options.title)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        
        Text(options.description)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 选中指示器
      if (options.isSelected) {
        Image($rawfile('check_circle.svg'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.brand'))
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(options.isSelected ? $r('app.color.brand_light') : $r('app.color.card_background'))
    .borderRadius(12)
    .border({
      width: options.isSelected ? 2 : 1,
      color: options.isSelected ? $r('app.color.brand') : $r('app.color.border')
    })
    .onClick(() => {
      this.selectedModel = options.modelType
      
      // 更新全局状态
      const modelState = AppStorageV2.connect(
        CurrentModelTypeState,
        AI_STORAGE_KEYS.CURRENT_MODEL_TYPE,
        () => new CurrentModelTypeState()
      )
      if (modelState !== undefined) {
        modelState.modelType = options.modelType
      }
      
      this.onModelSelectedCallback(options.modelType)
    })
    .animation({
      duration: 200,
      curve: Curve.EaseOut
    })
  }
}
