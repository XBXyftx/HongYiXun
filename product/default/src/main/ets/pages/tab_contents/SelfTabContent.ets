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

import { DEVICE_TYPES, NAV_DESTS, APP_STORAGE_KEYS, HistoryUpdateTrigger, FavoriteUpdateTrigger, LikeUpdateTrigger, NoteUpdateTrigger } from "common"
import { deviceInfo } from "@kit.BasicServicesKit"
import { historyManager, favoriteManager, likeManager, noteManager, NoteList } from "feature"
import { AppStorageV2 } from "@kit.ArkUI"

interface MenuCardItem {
  icon: Resource
  iconBgColor: ResourceColor
  title: string
  subtitle: string
  onClick: () => void
}

@ComponentV2
export struct SelfTabContent {
  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local navPathStuck: NavPathStack = AppStorageV2.connect(NavPathStack, APP_STORAGE_KEYS.NAV_PATH_STUCK, () => new NavPathStack())!
  @Local historyUpdateTrigger: HistoryUpdateTrigger =
    AppStorageV2.connect(HistoryUpdateTrigger, APP_STORAGE_KEYS.HISTORY_UPDATE_TRIGGER, () => new HistoryUpdateTrigger())!
  @Local favoriteUpdateTrigger: FavoriteUpdateTrigger =
    AppStorageV2.connect(FavoriteUpdateTrigger, APP_STORAGE_KEYS.FAVORITE_UPDATE_TRIGGER, () => new FavoriteUpdateTrigger())!
  @Local likeUpdateTrigger: LikeUpdateTrigger =
    AppStorageV2.connect(LikeUpdateTrigger, APP_STORAGE_KEYS.LIKE_UPDATE_TRIGGER, () => new LikeUpdateTrigger())!
  @Local noteUpdateTrigger: NoteUpdateTrigger =
    AppStorageV2.connect(NoteUpdateTrigger, APP_STORAGE_KEYS.NOTE_UPDATE_TRIGGER, () => new NoteUpdateTrigger())!
  @Local historyCount: number = 0
  @Local favoriteCount: number = 0
  @Local likeCount: number = 0
  @Local noteCount: number = 0
  @Local showNoteList: boolean = false

  async aboutToAppear(): Promise<void> {
    await this.updateHistoryCount()
    await this.updateFavoriteCount()
    await this.updateLikeCount()
    await this.updateNoteCount()
  }

  @Monitor('historyUpdateTrigger.trigger')
  async onHistoryUpdate(): Promise<void> {
    await this.updateHistoryCount()
  }

  @Monitor('favoriteUpdateTrigger.trigger')
  async onFavoriteUpdate(): Promise<void> {
    await this.updateFavoriteCount()
  }

  @Monitor('likeUpdateTrigger.trigger')
  async onLikeUpdate(): Promise<void> {
    await this.updateLikeCount()
  }

  @Monitor('noteUpdateTrigger.trigger')
  async onNoteUpdate(): Promise<void> {
    await this.updateNoteCount()
  }

  async updateHistoryCount(): Promise<void> {
    const historyList = await historyManager.getHistoryList()
    this.historyCount = historyList.length
  }

  async updateFavoriteCount(): Promise<void> {
    const favoriteList = await favoriteManager.getFavoriteList()
    this.favoriteCount = favoriteList.length
  }

  async updateLikeCount(): Promise<void> {
    const likeList = await likeManager.getLikeList()
    this.likeCount = likeList.length
  }

  async updateNoteCount(): Promise<void> {
    await noteManager.init()
    const noteList = await noteManager.getNoteList()
    this.noteCount = noteList.length
  }

  // 获取菜单项配置
  getMenuItems(): MenuCardItem[] {
    return [
      {
        icon: $rawfile('history_icon.svg'),
        iconBgColor: '#1DB954', // 绿色
        title: '浏览历史',
        subtitle: this.historyCount > 0 ? `${this.historyCount}条记录` : '暂无浏览记录',
        onClick: () => this.navPathStuck.pushPath({ name: NAV_DESTS.HISTORY })
      },
      {
        icon: $rawfile('favorite_icon.svg'),
        iconBgColor: '#00BCD4', // 青色
        title: '我的收藏',
        subtitle: this.favoriteCount > 0 ? `${this.favoriteCount}篇收藏` : '暂无收藏内容',
        onClick: () => this.navPathStuck.pushPath({ name: NAV_DESTS.FAVORITES })
      },
      {
        icon: $rawfile('like_icon.svg'),
        iconBgColor: '#FF6B9D', // 粉色
        title: '我的点赞',
        subtitle: this.likeCount > 0 ? `${this.likeCount}篇点赞` : '暂无点赞内容',
        onClick: () => this.navPathStuck.pushPath({ name: NAV_DESTS.LIKES })
      },
      {
        icon: $rawfile('settings_icon.svg'),
        iconBgColor: '#9C7CF4', // 紫色
        title: '设置',
        subtitle: '个性化配置',
        onClick: () => this.navPathStuck.pushPath({ name: NAV_DESTS.SETTINGS })
      }
    ]
  }

  @Builder
  MenuCardBuilder(item: MenuCardItem) {
    Column() {
      Row() {
        // 彩色圆形图标背景
        Stack() {
          Circle()
            .width(this.deviceType === DEVICE_TYPES.PHONE ? 44 : 52)
            .height(this.deviceType === DEVICE_TYPES.PHONE ? 44 : 52)
            .fill(item.iconBgColor)

          Image(item.icon)
            .width(this.deviceType === DEVICE_TYPES.PHONE ? 22 : 26)
            .height(this.deviceType === DEVICE_TYPES.PHONE ? 22 : 26)
            .fillColor(Color.White)
        }

        // 标题
        Text(item.title)
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 18 : 22)
          .fontWeight(600)
          .fontColor($r('app.color.text_primary'))
          .margin({ left: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 描述文字
      Text(item.subtitle)
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 13 : 16)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16 })
        .width('100%')
    }
    .width('100%')
    .padding(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
    .backgroundColor($r('app.color.news_list_item_bg'))
    .borderRadius(16)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => item.onClick())
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('我的')
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 28 : 34)
          .fontWeight(700)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .padding({
        left: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
        right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
        top: this.deviceType === DEVICE_TYPES.PHONE ? 20 : 28,
        bottom: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20
      })

      // 我的笔记入口 - 横条卡片
      Row() {
        // 图标
        Stack() {
          Circle()
            .width(this.deviceType === DEVICE_TYPES.PHONE ? 48 : 56)
            .height(this.deviceType === DEVICE_TYPES.PHONE ? 48 : 56)
            .fill('#FF9500')

          Image($rawfile('note_icon.svg'))
            .width(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 28)
            .height(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 28)
            .fillColor(Color.White)
        }

        Column() {
          Text('我的笔记')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 18 : 22)
            .fontWeight(600)
            .fontColor($r('app.color.text_primary'))

          Text(this.noteCount > 0 ? `${this.noteCount}篇笔记` : '记录阅读心得')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 13 : 16)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18 })
        .layoutWeight(1)

        Image($rawfile('arrow_right.svg'))
          .width(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
          .height(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
          .fillColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .padding(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
      .margin({
        left: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
        right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
        bottom: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16
      })
      .backgroundColor($r('app.color.news_list_item_bg'))
      .borderRadius(16)
      .onClick(() => {
        this.showNoteList = true
      })

      // 两列网格布局
      Scroll() {
        Column() {
          GridRow({
            columns: 2,
            gutter: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16
          }) {
            ForEach(this.getMenuItems(), (item: MenuCardItem, index: number) => {
              GridCol() {
                this.MenuCardBuilder(item)
              }
            })
          }
          .width('100%')
        }
        .padding({
          left: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
          right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
          bottom: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24
        })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .expandSafeArea()
    .bindContentCover(
      $$this.showNoteList,
      this.NoteListCoverBuilder(),
      {
        modalTransition: ModalTransition.DEFAULT
      }
    )
  }

  @Builder
  NoteListCoverBuilder() {
    NoteList({
      onClose: () => {
        this.showNoteList = false
      }
    })
  }
}
