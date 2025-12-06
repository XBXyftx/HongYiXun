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

import {
  NEWS_LIST_ITEM_ANIMATE_PARAM,
  DEVICE_TYPES,
  APP_STORAGE_KEYS,
  logger,
  LOG_TAG,
  NewsArticle,
  NewsListHeaderIsSticky,
  NEWS_LIST_ANIMATION_PARAM,
  NewsListDataSource,
  NAV_DESTS,
  NEWS_CATEGORIES,
  NEWS_CATEGORY,
  NewsCategoryInfo
} from "common"
import { AppStorageV2, curves } from "@kit.ArkUI"
import { deviceInfo } from "@kit.BasicServicesKit"
import { newsManager } from '../../managers/NewsManager'

@ComponentV2
export struct NewsList {
  @Param listScroller: Scroller = new Scroller()
  @Param newsList: NewsArticle[] = []
  @Param navStuck: NavPathStack = new NavPathStack()
  @Param refreshTrigger: number = 0  // 刷新触发器，用于父组件通知重新加载数据
  @Local navPathStuck: NavPathStack = AppStorageV2.connect(NavPathStack, APP_STORAGE_KEYS.NAV_PATH_STUCK, () => new NavPathStack())!
  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local isNewsListSticky: NewsListHeaderIsSticky =
    AppStorageV2.connect(NewsListHeaderIsSticky, APP_STORAGE_KEYS.IS_STICKY, () => new NewsListHeaderIsSticky())!
  @Local headerRadius: number = 20
  @Local headerAlignItems: HorizontalAlign = HorizontalAlign.Center
  @Local headerFontSize: number = this.deviceType === DEVICE_TYPES.PHONE ? 25 : 35
  @Local isOnAreaChange: boolean = false
  @Local newsListDataSource: NewsListDataSource = new NewsListDataSource()
  // 新增：当前选中的新闻栏目
  @Local currentCategory: NEWS_CATEGORY = NEWS_CATEGORY.OPENHARMONY_OFFICIAL
  // 新增：当前栏目的新闻列表
  @Local currentCategoryNews: NewsArticle[] = []
  // 新增：横向滚动控制器
  private categoryScroller: Scroller = new Scroller()

  @Monitor('newsList')
  resetDataSource() {
    logger.info(`${LOG_TAG.NEWS_LIST}捕获到newsList变化${this.newsList.length}`)
    this.newsListDataSource.resetData(this.newsList)
  }

  @Monitor('currentCategoryNews')
  resetCategoryDataSource() {
    logger.info(`${LOG_TAG.NEWS_LIST}捕获到当前栏目数据变化${this.currentCategoryNews.length}`)
    this.newsListDataSource.resetData(this.currentCategoryNews)
  }

  @Monitor('refreshTrigger')
  onRefreshTriggered() {
    if (this.refreshTrigger > 0) {
      logger.info(`${LOG_TAG.NEWS_LIST}捕获到刷新触发器变化: ${this.refreshTrigger}，重新加载当前栏目数据`)
      // 重新加载当前选中栏目的数据
      const currentCategoryInfo = NEWS_CATEGORIES.find(cat => cat.id === this.currentCategory)
      if (currentCategoryInfo && currentCategoryInfo.isDeveloped) {
        this.reloadCurrentCategoryData(currentCategoryInfo)
      }
    }
  }

  /**
   * 切换新闻栏目
   * 
   * @param categoryInfo - 栏目信息对象
   */
  switchCategory(categoryInfo: NewsCategoryInfo) {
    logger.info(`${LOG_TAG.NEWS_LIST}切换到栏目: ${categoryInfo.displayName}`)
    this.currentCategory = categoryInfo.id
    this.loadCategoryNews(categoryInfo)
  }

  /**
   * 加载指定栏目的新闻数据
   * 
   * @param categoryInfo - 栏目信息对象
   */
  async loadCategoryNews(categoryInfo: NewsCategoryInfo) {
    try {
      // 先从数据库读取
      const cachedNews = await newsManager.getCategoryNewsFromDB(categoryInfo.dbKey, categoryInfo.displayName)
      
      if (cachedNews && cachedNews.length > 0) {
        this.currentCategoryNews = cachedNews
        logger.info(`${LOG_TAG.NEWS_LIST}从缓存加载【${categoryInfo.displayName}】成功: ${cachedNews.length}条`)
      } else {
        this.currentCategoryNews = []
        logger.warn(`${LOG_TAG.NEWS_LIST}【${categoryInfo.displayName}】缓存为空`)
      }

      // 后台更新数据
      if (categoryInfo.isDeveloped) {
        newsManager.loadCategoryNewsToDB(categoryInfo.apiCategory, categoryInfo.dbKey).then((success: boolean) => {
          if (success) {
            // 重新加载数据
            newsManager.getCategoryNewsFromDB(categoryInfo.dbKey, categoryInfo.displayName).then((updatedNews: NewsArticle[] | null) => {
              if (updatedNews && this.currentCategory === categoryInfo.id) {
                this.currentCategoryNews = updatedNews
                logger.info(`${LOG_TAG.NEWS_LIST}【${categoryInfo.displayName}】后台更新成功`)
              }
            })
          }
        })
      }
    } catch (error) {
      logger.error(`${LOG_TAG.NEWS_LIST}加载【${categoryInfo.displayName}】失败: ${JSON.stringify(error)}`)
      this.currentCategoryNews = []
    }
  }

  /**
   * 重新加载当前栏目数据（仅从数据库读取，不请求网络）
   * 
   * 用于响应父组件的刷新触发，实时更新 UI
   * 
   * @param categoryInfo - 栏目信息对象
   */
  async reloadCurrentCategoryData(categoryInfo: NewsCategoryInfo) {
    try {
      const updatedNews = await newsManager.getCategoryNewsFromDB(
        categoryInfo.dbKey,
        categoryInfo.displayName
      )

      if (updatedNews) {
        this.currentCategoryNews = updatedNews
        logger.info(`${LOG_TAG.NEWS_LIST}[实时更新] 重新加载【${categoryInfo.displayName}】成功: ${updatedNews.length}条`)
      }
    } catch (error) {
      logger.error(`${LOG_TAG.NEWS_LIST}[实时更新] 重新加载【${categoryInfo.displayName}】失败: ${JSON.stringify(error)}`)
    }
  }

  @Builder
  NewsListHeaderBuilder() {
    Column() {
      // 横向分栏目录
      Row() {
        // 横向滚动列表
        List({ scroller: this.categoryScroller, space: this.deviceType === DEVICE_TYPES.PHONE ? 10 : 15 }) {
          ForEach(NEWS_CATEGORIES, (category: NewsCategoryInfo) => {
            ListItem() {
              Column() {
                Text(category.displayName)
                  .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 18 : 20)
                  .fontColor(this.currentCategory === category.id 
                    ? $r('app.color.news_list_header_font') 
                    : '#ffaeaeae')
                  .fontWeight(this.currentCategory === category.id ? FontWeight.Bold : FontWeight.Normal)
                  .padding({
                    left: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16,
                    right: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16,
                    top: this.deviceType === DEVICE_TYPES.PHONE ? 8 : 10,
                    bottom: this.deviceType === DEVICE_TYPES.PHONE ? 8 : 10
                  })
                
                // 选中指示器
                if (this.currentCategory === category.id) {
                  Divider()
                    .width('40%')
                    .height(2)
                    .color($r('app.color.news_list_header_font'))
                    .margin({ top: 2 })
                }
              }
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                if (category.isDeveloped) {
                  this.switchCategory(category)
                } else {
                  this.getUIContext()
                    .getPromptAction()
                    .showToast({ message: `${category.displayName}功能正在开发中，敬请期待`, duration: 2000 })
                }
              })
            }
          }, (item: NewsCategoryInfo) => item.id)
        }
        .listDirection(Axis.Horizontal)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .width('100%')
        .layoutWeight(1)

        // 回到顶部按钮
        if (this.isNewsListSticky.isSticky) {
          Image($rawfile('backToTop.svg'))
            .fillColor($r('app.color.back_to_top'))
            .width(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 30)
            .height(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 30)
            .margin({ left: 10, right: 10 })
            .transition(NEWS_LIST_ITEM_ANIMATE_PARAM)
            .onClick(() => {
              this.listScroller.scrollEdge(Edge.Top, { velocity: 6000 })
              this.isNewsListSticky.isSticky = false
            })
        }
      }
      .width('95%')
      .padding(10)
      .backgroundColor($r('app.color.news_list_header_bg'))
      .borderRadius(this.headerRadius)
      .margin({
        bottom: 15,
        left: 5,
        right: 5
      })
      .animation(NEWS_LIST_ANIMATION_PARAM)
    }
    .animation(NEWS_LIST_ANIMATION_PARAM)
    .onAreaChange((oldValue: Area, newValue: Area) => {
      if (!this.isOnAreaChange) {
        if (oldValue.position.y == 0 && newValue.position.y == 0) {
          this.isNewsListSticky.isSticky = false
        } else {
          this.isNewsListSticky.isSticky = true
          this.isOnAreaChange = true
          setTimeout(() => {
            this.isOnAreaChange = false
          }, 200)
        }
      }
    })
    .width('100%')
  }

  @Monitor('isNewsListSticky.isSticky')
  viewChange() {
    if (this.isNewsListSticky.isSticky) {
      this.headerRadius = 0
      this.headerAlignItems = HorizontalAlign.Start
      this.headerFontSize = this.deviceType === DEVICE_TYPES.PHONE ? 15 : 20
    } else {
      this.headerRadius = 20
      this.headerAlignItems = HorizontalAlign.Center
      this.headerFontSize = this.deviceType === DEVICE_TYPES.PHONE ? 25 : 35
    }
  }

  aboutToAppear(): void {
    setTimeout(() => {
      if (this.newsList.length == 0) {
        this.getUIContext()
          .getPromptAction()
          .showToast({ message: '后端数据正在更新请稍后下拉刷新或重启应用重试', duration: 5000 })
      }
      this.newsListDataSource.pushDataArr(this.newsList)
      
      // 加载默认栏目（开源鸿蒙资讯）的数据
      const defaultCategory = NEWS_CATEGORIES[0]
      this.loadCategoryNews(defaultCategory)
    }, 200)
  }

  build() {
    ListItemGroup({ header: this.NewsListHeaderBuilder(), space: this.deviceType === DEVICE_TYPES.PHONE ? 15 : 25 }) {
      LazyForEach(this.newsListDataSource, (news: NewsArticle) => {
        ListItem() {
          Column() {
            Column({ space: this.deviceType === DEVICE_TYPES.PHONE ? 10 : 20 }) {
              Text(news.title)
                .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
                .fontWeight(600)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .fontColor($r('app.color.text_primary'))
              Row() {
                Text(news.source ?? '')
                  .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16)
                  .fontColor($r('app.color.text_secondary'))
                  .maxLines(1)
                Text('·')
                  .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ left: 5, right: 5 })
                Text(news.date ?? '')
                  .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16)
                  .fontColor($r('app.color.text_secondary'))
              }
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding({
              top: 5,
              bottom: 5,
              left: 10,
              right: 10
            })
            .borderRadius(19)
            .backgroundColor($r('app.color.news_list_item_bg'))
          }
          .width('95%')
          .backgroundImage($rawfile('newsListItemBG.png'))
          .backgroundImagePosition(Alignment.TopStart)
          .borderWidth(2)
          .borderColor($r('app.color.news_list_item_border'))
          .backgroundColor($r('app.color.news_list_item_bg'))
          .borderRadius(20)

        }
        .onClick(() => {
          this.navStuck.replacePath({
            name: NAV_DESTS.ARTICLE,
            param: news
          })
        })
        .transition(NEWS_LIST_ITEM_ANIMATE_PARAM)
        .width('100%')
        .alignSelf(ItemAlign.Center)
      }, (item: NewsArticle, i: number) => {
        return `${item.id}+${i}`
      })
    }
    .borderRadius({
      topLeft: 20,
      topRight: 20
    })
  }
}