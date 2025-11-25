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
 * 首页顶部轮播图数据结构
 * 
 * 定义轮播图 API 响应的数据格式
 * 
 * @interface NewsSwiperResModule
 * 
 * @remarks
 * 用于首页顶部的新闻轮播图展示
 * 
 * @example
 * ```typescript
 * const swiperData: NewsSwiperResModule = {
 *   success: true,
 *   images: [
 *     "https://example.com/image1.jpg",
 *     "https://example.com/image2.jpg",
 *     "https://example.com/image3.jpg",
 *     "https://example.com/image4.jpg"
 *   ],
 *   total: 4,
 *   message: "获取成功",
 *   timestamp: "2025-01-15T14:30:56.789Z"
 * }
 * ```
 */
export interface NewsSwiperResModule {
  /** 
   * 请求是否成功
   * 
   * true 表示成功获取轮播图数据
   */
  success: boolean
  
  /** 
   * 轮播图图片 URL 数组
   * 
   * 包含所有轮播图的图片地址
   */
  images: ResourceStr[]
  
  /** 
   * 轮播图总数
   * 
   * 固定为 4 张图片
   */
  total: 4
  
  /** 
   * 响应消息
   * 
   * 描述请求结果的文本信息
   */
  message: string
  
  /** 
   * 时间戳
   * 
   * 数据生成的时间，ISO 8601 格式
   */
  timestamp: string
}
