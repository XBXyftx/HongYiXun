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
  AI_STORAGE_KEYS,
  AIModelType,
  ConversationHistoryList as ConversationHistoryListModel,
  ConversationRecord
} from 'ai_common'

/**
 * 会话历史列表组件
 * 
 * 显示所有历史对话记录
 */
@ComponentV2
export struct ConversationHistoryList {
  /** 选择会话回调 */
  @Param onSelectConversation: (conversationId: string) => void = () => {}
  /** 删除会话回调 */
  @Param onDeleteConversation: (conversationId: string) => void = () => {}
  
  @Local private conversationList: ConversationHistoryListModel = new ConversationHistoryListModel()

  aboutToAppear(): void {
    const list = AppStorageV2.connect(
      ConversationHistoryListModel,
      AI_STORAGE_KEYS.CONVERSATION_HISTORY_LIST,
      () => new ConversationHistoryListModel()
    )
    if (list) {
      this.conversationList = list
    }
  }

  /**
   * 获取模型类型显示名称
   */
  private getModelTypeName(modelType: AIModelType): string {
    switch (modelType) {
      case AIModelType.QUICK_ANSWER:
        return '快速回答'
      case AIModelType.DEEP_THINKING:
        return '深度思考'
      default:
        return '未知模式'
    }
  }

  /**
   * 格式化时间
   */
  private formatTime(timestamp: number): string {
    const date = new Date(timestamp)
    const now = new Date()
    const diff = now.getTime() - timestamp

    // 今天
    if (date.toDateString() === now.toDateString()) {
      return `今天 ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`
    }

    // 昨天
    const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000)
    if (date.toDateString() === yesterday.toDateString()) {
      return `昨天 ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`
    }

    // 其他日期
    return `${date.getMonth() + 1}/${date.getDate()} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`
  }

  build() {
    Column() {
      if (this.conversationList.length === 0) {
        // 空状态
        Column() {
          Image($rawfile('empty_history.svg'))
            .width(120)
            .height(120)
            .opacity(0.5)
          
          Text('暂无对话记录')
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 16 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 会话列表
        List() {
          ForEach(this.conversationList.getConversations(), (conversation: ConversationRecord) => {
            ListItem() {
              Row() {
                Column() {
                  // 标题
                  Text(conversation.title || '新对话')
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  // 模型类型和时间
                  Row() {
                    Text(this.getModelTypeName(conversation.modelType))
                      .fontSize(12)
                      .fontColor($r('app.color.brand'))
                      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      .backgroundColor($r('app.color.brand_light'))
                      .borderRadius(4)

                    Text(this.formatTime(conversation.updateTime))
                      .fontSize(12)
                      .fontColor($r('app.color.text_secondary'))
                      .margin({ left: 8 })
                  }
                  .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                // 删除按钮
                Button() {
                  Image($rawfile('delete.svg'))
                    .width(20)
                    .height(20)
                    .fillColor($r('app.color.text_secondary'))
                }
                .width(36)
                .height(36)
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  this.onDeleteConversation(conversation.id)
                })
              }
              .width('100%')
              .padding(16)
              .backgroundColor($r('app.color.card_background'))
              .borderRadius(12)
              .onClick(() => {
                this.onSelectConversation(conversation.id)
              })
            }
            .margin({ bottom: 8 })
          }, (conversation: ConversationRecord) => conversation.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
  }
}
