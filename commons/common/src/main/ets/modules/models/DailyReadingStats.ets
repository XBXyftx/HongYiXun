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

/**
 * 每日阅读统计接口
 * 
 * 用于存储用户每天阅读的新闻数量统计
 * 
 * @interface DailyReadingStats
 */
export interface DailyReadingStats {
  /** 
   * 日期字符串，格式：YYYY-MM-DD
   * @example "2025-12-04"
   */
  dateStr: string
  
  /** 
   * 当天阅读的新闻数量（已去重）
   */
  count: number
  
  /**
   * 当天阅读的新闻ID集合（用于去重）
   */
  articleIds: string[]
}

/**
 * 热力日历颜色系枚举
 */
export enum HeatmapColorScheme {
  /** 蓝色系 */
  BLUE = 'blue',
  /** 绿色系 */
  GREEN = 'green',
  /** 红色系 */
  RED = 'red',
  /** 灰色系 */
  GRAY = 'gray'
}

/**
 * 热力日历时间范围枚举
 */
export enum HeatmapTimeRange {
  /** 最近7天 */
  DAYS_7 = 7,
  /** 最近30天 */
  DAYS_30 = 30,
  /** 最近90天 */
  DAYS_90 = 90,
  /** 最近180天 */
  DAYS_180 = 180,
  /** 最近365天 */
  DAYS_365 = 365
}

/**
 * 热力日历颜色范围枚举
 */
export enum HeatmapColorRange {
  /** 0-10条 */
  RANGE_10 = 10,
  /** 0-50条 */
  RANGE_50 = 50,
  /** 0-100条 */
  RANGE_100 = 100,
  /** 0-500条 */
  RANGE_500 = 500
}
