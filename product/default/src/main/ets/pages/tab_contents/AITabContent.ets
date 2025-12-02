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

import { AppStorageV2, promptAction } from '@kit.ArkUI'
import {
  AIModelType,
  AI_STORAGE_KEYS,
  CurrentModelTypeState,
  MessageHistoryList,
  WaitingResponseState,
  AI_LOG_TAG,
  aiLogger
} from 'ai_common'
import {
  ModelSelector,
  ChatInput,
  MessageList,
  ConversationHistoryList,
  chatManager
} from 'ai_feature'

/**
 * AI对话页面
 * 
 * 包含模型选择、消息列表、输入框等功能
 */
@ComponentV2
export struct AITabContent {
  /** 当前模型类型状态 */
  @Local private modelState: CurrentModelTypeState = new CurrentModelTypeState()
  /** 消息列表 */
  @Local private messageList: MessageHistoryList = new MessageHistoryList()
  /** 等待响应状态 */
  @Local private waitingState: WaitingResponseState = new WaitingResponseState()
  /** 是否显示模型选择器 */
  @Local private showModelSelector: boolean = true
  /** 是否已初始化 */
  @Local private isInitialized: boolean = false
  /** 是否显示历史记录面板 */
  @Local private showHistorySheet: boolean = false

  aboutToAppear(): void {
    this.initPage()
  }

  /**
   * 初始化页面
   */
  private async initPage(): Promise<void> {
    // 连接全局状态
    const modelState = AppStorageV2.connect(
      CurrentModelTypeState,
      AI_STORAGE_KEYS.CURRENT_MODEL_TYPE,
      () => new CurrentModelTypeState()
    )
    if (modelState) {
      this.modelState = modelState
    }

    const messageList = AppStorageV2.connect(
      MessageHistoryList,
      AI_STORAGE_KEYS.CURRENT_MESSAGE_LIST,
      () => new MessageHistoryList()
    )
    if (messageList) {
      this.messageList = messageList
    }

    const waitingState = AppStorageV2.connect(
      WaitingResponseState,
      AI_STORAGE_KEYS.IS_WAITING_RESPONSE,
      () => new WaitingResponseState()
    )
    if (waitingState) {
      this.waitingState = waitingState
    }

    // 创建新会话
    chatManager.createNewConversation()
    
    this.isInitialized = true
    aiLogger.info(`${AI_LOG_TAG.AI_PAGE}页面初始化完成`)
  }

  /**
   * 处理模型选择
   */
  private handleModelSelected(modelType: AIModelType): void {
    aiLogger.info(`${AI_LOG_TAG.AI_PAGE}选择模型: ${modelType}`)
    // 模型选择后不立即隐藏选择器，等待第一次发送消息
  }

  /**
   * 处理发送消息
   */
  private async handleSendMessage(message: string): Promise<void> {
    if (this.modelState.modelType === AIModelType.NOT_SELECTED) {
      promptAction.openToast({ message: '请先选择对话模式' })
      return
    }

    // 隐藏模型选择器
    if (this.showModelSelector) {
      this.showModelSelector = false
    }

    // 深度思考模式提示
    if (this.modelState.modelType === AIModelType.DEEP_THINKING) {
      promptAction.openToast({ 
        message: '深度思考模式，回答生成可能需要较长时间，请耐心等待...',
        duration: 3000
      })
    }

    aiLogger.info(`${AI_LOG_TAG.AI_PAGE}发送消息: ${message.substring(0, 30)}...`)
    
    const success = await chatManager.sendMessage(message)
    if (!success) {
      promptAction.openToast({ message: '发送失败，请重试' })
    }
  }

  /**
   * 处理新建对话
   */
  private handleNewConversation(): void {
    chatManager.createNewConversation()
    this.showModelSelector = true
    promptAction.openToast({ message: '已创建新对话' })
    aiLogger.info(`${AI_LOG_TAG.AI_PAGE}创建新对话`)
  }

  /**
   * 处理查看历史记录
   */
  private handleViewHistory(): void {
    this.showHistorySheet = true
  }

  /**
   * 处理选择历史会话
   */
  private async handleSelectConversation(conversationId: string): Promise<void> {
    const success = await chatManager.loadConversation(conversationId)
    if (success) {
      this.showHistorySheet = false
      this.showModelSelector = false
      promptAction.openToast({ message: '已加载历史对话' })
    } else {
      promptAction.openToast({ message: '加载失败，请重试' })
    }
  }

  /**
   * 处理删除历史会话
   */
  private async handleDeleteConversation(conversationId: string): Promise<void> {
    const success = await chatManager.deleteConversation(conversationId)
    if (success) {
      promptAction.openToast({ message: '已删除' })
    } else {
      promptAction.openToast({ message: '删除失败' })
    }
  }

  /**
   * 历史记录面板内容
   */
  @Builder
  historySheetBuilder() {
    Column() {
      // 标题栏
      Row() {
        Text('历史对话')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        
        Blank()
        
        Button() {
          Image($rawfile('close.svg'))
            .width(20)
            .height(20)
            .fillColor($r('app.color.text_secondary'))
        }
        .width(36)
        .height(36)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.showHistorySheet = false
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      // 历史记录列表
      ConversationHistoryList({
        onSelectConversation: (conversationId: string) => {
          this.handleSelectConversation(conversationId)
        },
        onDeleteConversation: (conversationId: string) => {
          this.handleDeleteConversation(conversationId)
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }

  build() {
    Column() {
      // 顶部工具栏
      Row() {
        Text('鸿小易')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))

        Blank()

        // 新建对话按钮
        Button() {
          Image($rawfile('new_chat.svg'))
            .width(20)
            .height(20)
            .fillColor($r('app.color.text_secondary'))
        }
        .width(36)
        .height(36)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.handleNewConversation()
        })

        // 历史记录按钮
        Button() {
          Image($rawfile('history.svg'))
            .width(20)
            .height(20)
            .fillColor($r('app.color.text_secondary'))
        }
        .width(36)
        .height(36)
        .backgroundColor(Color.Transparent)
        .margin({ left: 8 })
        .onClick(() => {
          this.handleViewHistory()
        })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor($r('app.color.card_background'))

      // 主内容区域
      if (this.showModelSelector && this.messageList.length === 0) {
        // 显示模型选择器
        Column() {
          Blank()
          
          ModelSelector({
            onModelSelectedCallback: (modelType: AIModelType) => {
              this.handleModelSelected(modelType)
            }
          })
          
          Blank()
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 显示消息列表
        MessageList()
      }

      // 深度思考模式等待提示
      if (this.waitingState.isWaiting && this.modelState.modelType === AIModelType.DEEP_THINKING) {
        Row() {
          LoadingProgress()
            .width(20)
            .height(20)
            .color($r('app.color.brand'))
          
          Text('深度思考中，请耐心等待...')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ left: 8 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor($r('app.color.warning_light'))
        .animation({
          duration: 500,
          iterations: -1,
          playMode: PlayMode.Alternate
        })
      }

      // 输入框
      ChatInput({
        onSendCallback: (message: string) => {
          this.handleSendMessage(message)
        },
        disabled: !this.isInitialized
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
    .expandSafeArea()
    .bindSheet(this.showHistorySheet, this.historySheetBuilder(), {
      height: SheetSize.MEDIUM,
      dragBar: true,
      showClose: false,
      backgroundColor: $r('app.color.page_background'),
      onDisappear: () => {
        this.showHistorySheet = false
      }
    })
  }
}
