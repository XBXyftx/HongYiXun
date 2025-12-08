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
import { AppStorageV2, ComponentContent, mediaquery } from '@kit.ArkUI'
import {
  BREAK_POINT_ENUM as BREAK_POINT_ENUM,
  BreakpointState,
  BreakpointSystem,
  DEVICE_TYPES,
  logger,
  NAV_DESTS,
  APP_STORAGE_KEYS,
  LOG_TAG
} from 'common'
import { ColorModChoseButton, FontSizeAdjustButton } from 'feature'
import { MainPage } from './nav_pages/MainPage'
import { deviceInfo } from '@kit.BasicServicesKit'
import { ArticlePage } from './nav_pages/ArticlePage'
import { HistoryPage } from './nav_pages/HistoryPage'
import { SettingsPage } from './nav_pages/SettingsPage'
import { FontSizeSettingsPage } from './nav_pages/FontSizeSettingsPage'
import { ColorModeSettingsPage } from './nav_pages/ColorModeSettingsPage'
import { FavoritesPage } from './nav_pages/FavoritesPage'
import { AIChatPage } from './nav_pages/AIChatPage'
import { LikesPage } from './nav_pages/LikesPage'
import { HeatmapSettingsPage } from './nav_pages/HeatmapSettingsPage'
import { DateHistoryPage } from './nav_pages/DateHistoryPage'
import { SearchPage } from './nav_pages/SearchPage'
import { NotesPage } from './nav_pages/NotesPage'
import { NoteEditorStyleSettingsPage } from './nav_pages/NoteEditorStyleSettingsPage'


@Builder
function PlaceholderPage() {
  Column({ space: 20 }) {
    // Logo
    Image($r('app.media.logo'))
      .width(180)
      .height(180)
      .borderRadius(24)
      .shadow({
        radius: 20,
        color: '#3300BE53',
        offsetX: 0,
        offsetY: 8
      })

    // 应用名称
    Text('鸿易讯')
      .fontSize(42)
      .fontWeight(700)
      .fontColor($r('app.color.text_primary'))

    // 副标题
    Text('开源鸿蒙资讯聚合阅读')
      .fontSize(26)
      .fontColor($r('app.color.text_secondary'))
      .margin({ top: -8 })


    Text('从左侧选择文章开始阅读')
      .fontSize(24)
      .fontColor($r('app.color.text_secondary'))

  }
  .justifyContent(FlexAlign.Center)
  .width("100%")
  .height("100%")
}

@Entry
@ComponentV2
struct Main {
  @Local navPathStuck: NavPathStack =
    AppStorageV2.connect(NavPathStack, APP_STORAGE_KEYS.NAV_PATH_STUCK, () => new NavPathStack())!
  @Local breakpointSystem: BreakpointSystem = BreakpointSystem.getInstance(this.getUIContext())
  @Local navMod: NavigationMode = NavigationMode.Stack
  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local breakPointState: BreakpointState = BreakpointState.of()
  placeholder = new ComponentContent(this.getUIContext(), wrapBuilder(PlaceholderPage))

  /**
   * 启动页跳转至主页面入场动画
   */
  pageTransition() {
    PageTransitionEnter({ type: RouteType.None, duration: 200, curve: Curve.EaseInOut })
      .scale({ x: 0.2, y: 0.2 })
      .opacity(0)
  }

  /**
   * 横竖屏切换监听器
   */
  orientationMatch() {
    const mediaQueryListener: mediaquery.MediaQueryListener =
      this.getUIContext().getMediaQuery().matchMediaSync('(orientation: landscape)')
    mediaQueryListener.on('change', () => {
      logger.info(`${LOG_TAG.INDEX_PAGE}横竖屏发生变化`)
      this.getNavMode()
    })
  }

  /**
   * NavMod切换器函数
   */
  @Monitor('breakPointState.value')
  getNavMode() {
    if (this.breakPointState.getCurrentBreakPointType() === BREAK_POINT_ENUM.xs ||
      this.breakPointState.getCurrentBreakPointType() === BREAK_POINT_ENUM.sm ||
      this.breakPointState.getCurrentBreakPointType() === BREAK_POINT_ENUM.md
    ) {
      this.navMod = NavigationMode.Stack
    } else {
      this.navMod = NavigationMode.Split
    }
  }

  @Builder
  NavDestMap(name: string) {
    if (name === NAV_DESTS.MAIN) {
      Main()
    } else if (name === NAV_DESTS.ARTICLE) {
      ArticlePage()
    } else if (name === NAV_DESTS.HISTORY) {
      HistoryPage()
    } else if (name === NAV_DESTS.SETTINGS) {
      SettingsPage()
    } else if (name === NAV_DESTS.FONT_SIZE_SETTINGS) {
      FontSizeSettingsPage()
    } else if (name === NAV_DESTS.COLOR_MODE_SETTINGS) {
      ColorModeSettingsPage()
    } else if (name === NAV_DESTS.FAVORITES) {
      FavoritesPage()
    } else if (name === NAV_DESTS.AI_CHAT) {
      AIChatPage()
    } else if (name === NAV_DESTS.LIKES) {
      LikesPage()
    } else if (name === NAV_DESTS.HEATMAP_SETTINGS) {
      HeatmapSettingsPage()
    } else if (name === NAV_DESTS.DATE_HISTORY) {
      DateHistoryPage()
    } else if (name === NAV_DESTS.SEARCH) {
      SearchPage()
    } else if (name === NAV_DESTS.NOTE_LIST) {
      NotesPage()
    } else if (name === NAV_DESTS.NOTE_EDITOR_STYLE_SETTINGS) {
      NoteEditorStyleSettingsPage()
    }
  }

  aboutToAppear(): void {
    this.breakpointSystem.attach(this.breakPointState)
    this.breakpointSystem.start()
    this.orientationMatch()
    this.getNavMode()
  }

  build() {
    Navigation(this.navPathStuck) {
      MainPage()
    }
    .splitPlaceholder(this.placeholder)
    .backgroundColor(Color.Transparent)
    .expandSafeArea()
    .navDestination(this.NavDestMap)
    .hideToolBar(true)
    .height('100%')
    .width('100%')
    .navBarWidth('40%')
    .hideBackButton(true)
    .hideTitleBar(true)
    .mode(this.navMod)
    .expandSafeArea()
  }
}