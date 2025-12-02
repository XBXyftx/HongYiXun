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

import { AppStorageV2, promptAction, window } from '@kit.ArkUI'
import {
  AIModelType,
  AI_STORAGE_KEYS,
  CurrentModelTypeState,
  MessageHistoryList,
  WaitingResponseState,
  AIErrorState,
  AI_LOG_TAG,
  aiLogger
} from 'ai_common'
import { APP_STORAGE_KEYS } from 'common'
import {
  ChatInput,
  MessageList,
  ConversationHistoryList,
  chatManager
} from 'ai_feature'

/**
 * AI对话页面参数
 */
export interface AIChatPageParam {
  modelType: AIModelType
}

/**
 * AI对话页面
 * 
 * 独立的AI对话页面，通过NavStack导航进入
 */
@ComponentV2
export struct AIChatPage {
  /** 导航栈 */
  @Local private navPathStuck: NavPathStack = new NavPathStack()
  /** 当前模型类型状态 */
  @Local private modelState: CurrentModelTypeState = new CurrentModelTypeState()
  /** 消息列表 */
  @Local private messageList: MessageHistoryList = new MessageHistoryList()
  /** 等待响应状态 */
  @Local private waitingState: WaitingResponseState = new WaitingResponseState()
  /** 是否已初始化 */
  @Local private isInitialized: boolean = false
  /** 是否显示历史记录面板 */
  @Local private showHistorySheet: boolean = false
  /** 键盘高度 */
  @Local private keyboardHeight: number = 0
  /** 错误状态 */
  @Local private errorState: AIErrorState = new AIErrorState()

  aboutToAppear(): void {
    this.initPage()
    this.initKeyboardListener()
  }


  /**
   * 初始化键盘监听
   */
  private initKeyboardListener(): void {
    const context = this.getUIContext().getHostContext()
    if (context === undefined) {
      return
    }
    
    window.getLastWindow(context).then((currentWindow: window.Window) => {
      currentWindow.on('avoidAreaChange', (data: window.AvoidAreaOptions) => {
        if (data.type === window.AvoidAreaType.TYPE_KEYBOARD) {
          this.keyboardHeight = px2vp(data.area.bottomRect.height)
        }
      })
    }).catch((err: Error) => {
      aiLogger.error(`${AI_LOG_TAG.AI_PAGE}初始化键盘监听失败: ${err.message}`)
    })
  }

  /**
   * 初始化页面
   */
  private async initPage(): Promise<void> {
    // 连接导航栈
    const navStack = AppStorageV2.connect(
      NavPathStack,
      APP_STORAGE_KEYS.NAV_PATH_STUCK,
      () => new NavPathStack()
    )
    if (navStack) {
      this.navPathStuck = navStack
    }

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

    const errorState = AppStorageV2.connect(
      AIErrorState,
      AI_STORAGE_KEYS.ERROR_STATE,
      () => new AIErrorState()
    )
    if (errorState) {
      this.errorState = errorState
    }

    // 创建新会话
    chatManager.createNewConversation()
    
    this.isInitialized = true
    aiLogger.info(`${AI_LOG_TAG.AI_PAGE}AI对话页面初始化完成`)
  }

  /**
   * 处理发送消息
   */
  private async handleSendMessage(message: string): Promise<void> {
    if (this.modelState.modelType === AIModelType.NOT_SELECTED) {
      promptAction.openToast({ message: '请先选择对话模式' })
      return
    }

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
    promptAction.openToast({ message: '已创建新对话' })
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
   * 获取模型名称
   */
  private getModelName(): string {
    if (this.modelState.modelType === AIModelType.QUICK_ANSWER) {
      return '快速回答'
    } else if (this.modelState.modelType === AIModelType.DEEP_THINKING) {
      return '深度思考'
    }
    return '鸿小易'
  }

  /**
   * 历史记录面板内容
   */
  @Builder
  historySheetBuilder() {
    Column() {
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
    NavDestination() {
      Column() {
        // 顶部工具栏
        Row() {
          // 返回按钮
          Button() {
            Image($rawfile('back.svg'))
              .width(24)
              .height(24)
              .fillColor($r('app.color.text_primary'))
          }
          .width(40)
          .height(40)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.navPathStuck.pop()
          })

          Text(this.getModelName())
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .margin({ left: 8 })

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
        .padding({ left: 8, right: 16 })
        .backgroundColor($r('app.color.card_background'))

        // 消息列表
        MessageList()
          .width('100%')
          .layoutWeight(1)

        // 状态提示条
        if (this.errorState.hasError) {
          Row() {
            Image($rawfile('error.svg'))
              .width(20)
              .height(20)
              .fillColor($r('app.color.error'))
            
            Text(this.errorState.errorMessage)
              .fontSize(14)
              .fontColor($r('app.color.error'))
              .margin({ left: 8 })
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
            
            Button() {
              Image($rawfile('close.svg'))
                .width(16)
                .height(16)
                .fillColor($r('app.color.text_secondary'))
            }
            .width(28)
            .height(28)
            .backgroundColor(Color.Transparent)
            .margin({ left: 8 })
            .onClick(() => {
              this.errorState.clearError()
            })
          }
          .width('100%')
          .padding({ left: 16, right: 8, top: 8, bottom: 8 })
          .backgroundColor($r('app.color.error_light'))
        } else if (this.waitingState.isWaiting) {
          Row() {
            LoadingProgress()
              .width(20)
              .height(20)
              .color($r('app.color.brand'))
            
            Text(this.modelState.modelType === AIModelType.DEEP_THINKING 
              ? '深度思考中，请耐心等待...' 
              : '正在生成回答...')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .margin({ left: 8 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor($r('app.color.warning_light'))
        }

        // 输入框
        Column() {
          ChatInput({
            onSendCallback: (message: string) => {
              this.handleSendMessage(message)
            },
            disabled: !this.isInitialized
          })
        }
        .width('100%')
        .margin({ bottom: this.keyboardHeight })
        .animation({
          duration: 200,
          curve: Curve.EaseOut
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_background'))
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      // 获取传入的模型类型参数
      const param = context.pathInfo.param as AIChatPageParam
      if (param && param.modelType) {
        this.modelState.modelType = param.modelType
      }
    })
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
