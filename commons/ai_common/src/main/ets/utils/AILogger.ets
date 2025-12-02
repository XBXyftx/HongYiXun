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

import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0001
const TAG = 'AI_MODULE'

/**
 * AI模块日志工具类
 */
class AILogger {
  debug(message: string): void {
    hilog.debug(DOMAIN, TAG, message)
  }

  info(message: string): void {
    hilog.info(DOMAIN, TAG, message)
  }

  warn(message: string): void {
    hilog.warn(DOMAIN, TAG, message)
  }

  error(message: string): void {
    hilog.error(DOMAIN, TAG, message)
  }
}

export const aiLogger = new AILogger()
