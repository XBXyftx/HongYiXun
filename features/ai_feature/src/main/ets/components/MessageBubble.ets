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

import { MessageRole, ViewMessageModel } from 'ai_common'

/**
 * 消息气泡组件
 * 
 * 根据消息角色显示不同样式的气泡
 */
@ComponentV2
export struct MessageBubble {
  @Param message: ViewMessageModel = new ViewMessageModel()

  build() {
    Row() {
      if (this.message.role === MessageRole.User) {
        // 用户消息 - 右对齐
        Blank()
        
        Column() {
          Text(this.message.content)
            .fontSize(16)
            .fontColor(Color.White)
            .lineHeight(24)
        }
        .padding(12)
        .backgroundColor($r('app.color.brand'))
        .borderRadius({
          topLeft: 16,
          topRight: 4,
          bottomLeft: 16,
          bottomRight: 16
        })
        .constraintSize({ maxWidth: '80%' })
      } else {
        // AI消息 - 左对齐
        Row() {
          // AI头像
          Image($rawfile('ai_avatar.svg'))
            .width(32)
            .height(32)
            .borderRadius(16)
            .margin({ right: 8 })

          Column() {
            Text(this.message.content)
              .fontSize(16)
              .fontColor($r('app.color.text_primary'))
              .lineHeight(24)
            
            // 加载指示器（消息未完成时显示）
            if (!this.message.hasEnd) {
              Row() {
                LoadingProgress()
                  .width(16)
                  .height(16)
                  .color($r('app.color.brand'))
                Text('正在思考...')
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ left: 4 })
              }
              .margin({ top: 8 })
            }
          }
          .padding(12)
          .backgroundColor($r('app.color.ai_bubble_background'))
          .borderRadius({
            topLeft: 4,
            topRight: 16,
            bottomLeft: 16,
            bottomRight: 16
          })
          .constraintSize({ maxWidth: '80%' })
          .alignItems(HorizontalAlign.Start)
        }
        .alignItems(VerticalAlign.Top)
        
        Blank()
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }
}
