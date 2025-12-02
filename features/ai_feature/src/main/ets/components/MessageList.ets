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
  MessageHistoryList,
  ViewMessageModel
} from 'ai_common'
import { MessageBubble } from './MessageBubble'

/**
 * 消息列表组件
 * 
 * 显示对话历史记录
 */
@ComponentV2
export struct MessageList {
  @Local private messageList: MessageHistoryList = new MessageHistoryList()
  @Local private currentReceivingMsg: ViewMessageModel = new ViewMessageModel()
  
  private scroller: Scroller = new Scroller()

  aboutToAppear(): void {
    // 连接消息列表
    const list = AppStorageV2.connect(
      MessageHistoryList,
      AI_STORAGE_KEYS.CURRENT_MESSAGE_LIST,
      () => new MessageHistoryList()
    )
    if (list) {
      this.messageList = list
    }

    // 连接当前接收消息
    const currentMsg = AppStorageV2.connect(
      ViewMessageModel,
      AI_STORAGE_KEYS.CURRENT_RECEIVING_MESSAGE,
      () => new ViewMessageModel()
    )
    if (currentMsg) {
      this.currentReceivingMsg = currentMsg
    }
  }

  build() {
    List({ scroller: this.scroller }) {
      // 历史消息
      ForEach(this.messageList.getMessages(), (message: ViewMessageModel) => {
        ListItem() {
          MessageBubble({ message: message })
        }
      }, (message: ViewMessageModel) => message.id)

      // 当前正在接收的消息（如果有内容）
      if (this.currentReceivingMsg.content.length > 0 && !this.currentReceivingMsg.hasEnd) {
        ListItem() {
          MessageBubble({ message: this.currentReceivingMsg })
        }
      }
    }
    .width('100%')
    .layoutWeight(1)
    .edgeEffect(EdgeEffect.Spring)
    .onReachEnd(() => {
      // 自动滚动到底部
    })
  }

  /**
   * 滚动到底部
   */
  scrollToBottom(): void {
    this.scroller.scrollEdge(Edge.Bottom)
  }
}
