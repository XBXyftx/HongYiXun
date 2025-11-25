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
 * 服务端相关的数据模型已迁移到 models 目录
 * 
 * @see commons/common/src/main/ets/modules/models/ServerModels.ets
 * 
 * 导出的类型：
 * - NewsSource: 新闻源信息接口
 * - CacheService: 缓存服务状态接口
 * - Services: 服务集合接口
 * - Endpoints: 接口端点集合接口
 * - SystemStatus: 系统状态根接口
 * - ServerStatus: 服务端状态枚举
 */

// 从 models 重新导出，保持向后兼容
export { NewsSource, CacheService, Services, Endpoints, SystemStatus, ServerStatus } from '../models/ServerModels'