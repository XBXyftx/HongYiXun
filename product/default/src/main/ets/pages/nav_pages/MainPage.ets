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

import { AITabContent } from "../tab_contents/AITabContent"
import { CalenderTabContent } from "../tab_contents/CalenderTabContent"
import { NewsHistoryTabContent } from "../tab_contents/NewsHistoryTabContent"
import { NewsListTabContent } from "../tab_contents/NewsListTabContent"
import { SelfTabContent } from "../tab_contents/SelfTabContent"

@Preview
@ComponentV2
export struct MainPage {
  @Local currentTabIndex: number = 0

  @Builder
  tabBarBuilder(title: string, targetIndex: number, selectedIcon: Resource, normalIcon: Resource) {
    Column() {
      Image(this.currentTabIndex === targetIndex ? selectedIcon : normalIcon)
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
      Text(title)
        .fontSize(16)
        .fontWeight(this.currentTabIndex === targetIndex ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.currentTabIndex === targetIndex ? $r('app.color.brand') : $r('app.color.text_secondary'))
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    NavDestination() {
      Tabs({ index: $$this.currentTabIndex }) {
        // 新闻子页
        TabContent() {
          NewsListTabContent()
        }
        .tabBar(this.tabBarBuilder('新闻', 0, $rawfile('TabBarNews.svg'), $rawfile('TabBarNewsSelected.svg')))

        // // AI问答子页面
        // TabContent() {
        //   AITabContent()
        // }
        // .tabBar(this.tabBarBuilder('鸿小易', 1, $rawfile('TabBarAI.svg'), $rawfile('TabBarAISelected.svg')))

        // 历史记录子页
        TabContent() {
          NewsHistoryTabContent()
        }
        .tabBar(this.tabBarBuilder('历史', 1,$rawfile('TabBarNewsHistorySelected.svg'),$rawfile('TabBarNewsHistory.svg')))

        // 热力日历子页
        TabContent() {
          CalenderTabContent()
        }
        .tabBar(this.tabBarBuilder('日历', 2,  $rawfile('TabBarForumSelected.svg'),$rawfile('TabBarForum.svg')))

        // 我的子页面
        TabContent() {
          SelfTabContent()
        }
        .tabBar(this.tabBarBuilder('我的', 3, $rawfile('TabBarSelf.svg'), $rawfile('TabBarSelfSelected.svg')))
      }
      .barMode(BarMode.Fixed)
      .barPosition(BarPosition.End)
      .animationDuration(300)
      .onChange((index: number) => {
        this.currentTabIndex = index
      })
    }
    .linearGradient({
      angle: 20,
      colors: [
        [$r('app.color.index_page_background_1'), 0],
        [$r('app.color.index_page_background_2'), 0.4],
        [$r('app.color.index_page_background_3'), 0.7],
        [$r('app.color.index_page_background_4'), 1]
      ]
    })
  }
}
