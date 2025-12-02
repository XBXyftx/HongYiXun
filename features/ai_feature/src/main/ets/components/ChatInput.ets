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
  WaitingResponseState,
  InputConfig
} from 'ai_common'

/**
 * 聊天输入框组件
 * 
 * 包含文本输入框和发送按钮，支持动画效果
 */
@ComponentV2
export struct ChatInput {
  /** 发送消息回调 */
  @Param onSendCallback: (message: string) => void = () => {}
  /** 是否禁用输入 */
  @Param disabled: boolean = false
  
  @Local private inputText: string = ''
  @Local private showSendButton: boolean = false
  @Local private sendButtonOffset: number = 100 // 初始在屏幕外

  /** 等待响应状态 */
  @Local private waitingState: WaitingResponseState = new WaitingResponseState()

  aboutToAppear(): void {
    const state = AppStorageV2.connect(
      WaitingResponseState,
      AI_STORAGE_KEYS.IS_WAITING_RESPONSE,
      () => new WaitingResponseState()
    )
    if (state !== undefined) {
      this.waitingState = state
    }
  }

  /**
   * 检查是否可以发送
   */
  private canSend(): boolean {
    return this.inputText.trim().length >= InputConfig.MIN_LENGTH &&
           this.inputText.length <= InputConfig.MAX_LENGTH &&
           !this.disabled &&
           !this.waitingState.isWaiting
  }

  /**
   * 处理发送
   */
  private handleSend(): void {
    if (!this.canSend()) {
      return
    }
    
    const message: string = this.inputText.trim()
    this.inputText = ''
    this.showSendButton = false
    this.sendButtonOffset = 100
    
    this.onSendCallback(message)
  }

  /**
   * 处理输入变化
   */
  private handleInputChange(value: string): void {
    this.inputText = value
    
    // 控制发送按钮显示动画
    if (value.trim().length > 0 && !this.showSendButton) {
      this.showSendButton = true
      // 延迟执行动画
      setTimeout(() => {
        this.sendButtonOffset = 0
      }, 10)
    } else if (value.trim().length === 0 && this.showSendButton) {
      this.sendButtonOffset = 100
      setTimeout(() => {
        this.showSendButton = false
      }, 300)
    }
  }

  build() {
    Row() {
      // 输入框
      TextInput({ text: this.inputText, placeholder: InputConfig.PLACEHOLDER })
        .layoutWeight(1)
        .height(44)
        .backgroundColor($r('app.color.input_background'))
        .borderRadius(22)
        .padding({ left: 16, right: 16 })
        .fontSize(16)
        .maxLength(InputConfig.MAX_LENGTH)
        .onChange((value: string) => {
          this.handleInputChange(value)
        })
        .onSubmit(() => {
          this.handleSend()
        })
        .enabled(!this.disabled && !this.waitingState.isWaiting)

      // 发送按钮（带动画）
      if (this.showSendButton) {
        Button() {
          if (this.waitingState.isWaiting) {
            LoadingProgress()
              .width(24)
              .height(24)
              .color(Color.White)
          } else {
            Image($rawfile('send.svg'))
              .width(24)
              .height(24)
              .fillColor(Color.White)
          }
        }
        .width(44)
        .height(44)
        .borderRadius(22)
        .backgroundColor(this.canSend() ? $r('app.color.brand') : $r('app.color.disabled'))
        .margin({ left: 12 })
        .enabled(this.canSend())
        .onClick(() => {
          this.handleSend()
        })
        .translate({ x: this.sendButtonOffset })
        .animation({
          duration: 300,
          curve: Curve.EaseOut
        })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.card_background'))
  }
}
