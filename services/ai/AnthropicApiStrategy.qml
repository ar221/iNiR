import QtQuick

ApiStrategy {
    property bool isReasoning: false
    property var toolUseByIndex: ({})

    function buildEndpoint(model) {
        return model.endpoint
    }

    function buildRequestData(model, messages, systemPrompt, temperature, tools, filePath) {
        const anthropicMessages = messages.map(message => {
            const hasFunctionCall = message.functionCall !== undefined && (message.functionName ?? "").length > 0

            if (hasFunctionCall && (message.functionResponse ?? "").length > 0) {
                const toolUseId = message.functionCall?.id ?? `${message.functionName}-call`
                return {
                    "role": "user",
                    "content": [{
                        "type": "tool_result",
                        "tool_use_id": toolUseId,
                        "content": String(message.functionResponse ?? "")
                    }]
                }
            }

            if (message.role === "assistant" && hasFunctionCall) {
                const toolUseId = message.functionCall?.id ?? `${message.functionName}-call`
                return {
                    "role": "assistant",
                    "content": [{
                        "type": "tool_use",
                        "id": toolUseId,
                        "name": message.functionName,
                        "input": message.functionCall?.args ?? {}
                    }]
                }
            }

            return {
                "role": message.role === "assistant" ? "assistant" : "user",
                "content": [{
                    "type": "text",
                    "text": String(message.rawContent ?? "")
                }]
            }
        })

        let baseData = {
            "model": model.model,
            "messages": anthropicMessages,
            "system": [{
                "type": "text",
                "text": systemPrompt
            }],
            "stream": true,
            "max_tokens": 4096,
            "temperature": temperature,
        }

        if (tools && tools.length > 0)
            baseData.tools = tools

        return model.extraParams ? Object.assign({}, baseData, model.extraParams) : baseData
    }

    function buildAuthorizationHeader(apiKeyEnvVarName) {
        // Proxy resolves OAuth/session token itself; no bearer needed from shell.
        return ""
    }

    function parseResponseLine(line, message) {
        let cleanData = line.trim()
        if (cleanData.startsWith("event:"))
            return {}

        if (cleanData.startsWith("data:"))
            cleanData = cleanData.slice(5).trim()

        if (!cleanData || cleanData.startsWith(":"))
            return {}

        if (cleanData === "[DONE]")
            return { finished: true }

        try {
            const dataJson = JSON.parse(cleanData)

            if (dataJson.error) {
                const errorMsg = `**Error**: ${dataJson.error.message || JSON.stringify(dataJson.error)}`
                message.rawContent += errorMsg
                message.content += errorMsg
                return { finished: true }
            }

            if (dataJson.type === "content_block_start") {
                const block = dataJson.content_block
                if (block?.type === "tool_use") {
                    toolUseByIndex[dataJson.index] = {
                        id: block.id,
                        name: block.name,
                        inputText: "",
                        inputObj: block.input ?? {}
                    }
                }
                return {}
            }

            if (dataJson.type === "content_block_delta") {
                const delta = dataJson.delta

                if (delta?.type === "text_delta") {
                    if (isReasoning) {
                        isReasoning = false
                        const endBlock = "\n\n</think>\n\n"
                        message.content += endBlock
                        message.rawContent += endBlock
                    }
                    const text = delta.text ?? ""
                    message.content += text
                    message.rawContent += text
                    return {}
                }

                if (delta?.type === "thinking_delta") {
                    if (!isReasoning) {
                        isReasoning = true
                        const startBlock = "\n\n<think>\n\n"
                        message.content += startBlock
                        message.rawContent += startBlock
                    }
                    const thinkingText = delta.thinking ?? ""
                    message.content += thinkingText
                    message.rawContent += thinkingText
                    return {}
                }

                if (delta?.type === "input_json_delta") {
                    const idx = dataJson.index
                    if (!toolUseByIndex[idx]) {
                        toolUseByIndex[idx] = {
                            id: `tool-${idx}`,
                            name: "",
                            inputText: "",
                            inputObj: {}
                        }
                    }
                    toolUseByIndex[idx].inputText += (delta.partial_json ?? "")
                    return {}
                }
            }

            if (dataJson.type === "content_block_stop") {
                const idx = dataJson.index
                const block = toolUseByIndex[idx]
                if (!block || !block.name)
                    return {}

                let args = block.inputObj ?? {}
                if ((block.inputText ?? "").trim().length > 0) {
                    try {
                        args = JSON.parse(block.inputText)
                    } catch (e) {
                        args = block.inputObj ?? {}
                    }
                }

                const newContent = `\n\n[[ Function: ${block.name}(${JSON.stringify(args, null, 2)}) ]]\n`
                message.rawContent += newContent
                message.content += newContent
                message.functionName = block.name
                message.functionCall = block.name

                delete toolUseByIndex[idx]
                return { functionCall: { name: block.name, args: args, id: block.id } }
            }

            if (dataJson.type === "message_delta") {
                const stopReason = dataJson.delta?.stop_reason ?? ""
                const usage = dataJson.usage
                const usageResult = usage ? {
                    tokenUsage: {
                        input: usage.input_tokens ?? -1,
                        output: usage.output_tokens ?? -1,
                        total: (usage.input_tokens ?? 0) + (usage.output_tokens ?? 0),
                    }
                } : {}

                if (stopReason === "end_turn" || stopReason === "max_tokens" || stopReason === "stop_sequence")
                    return Object.assign({}, usageResult, { finished: true })

                return usageResult
            }

            if (dataJson.type === "message_stop")
                return { finished: true }

        } catch (e) {
            console.log("[AI] Anthropic: Could not parse line:", e)
            message.rawContent += line
            message.content += line
        }

        return {}
    }

    function onRequestFinished(message) {
        if (isReasoning) {
            isReasoning = false
            const endBlock = "\n\n</think>\n\n"
            message.content += endBlock
            message.rawContent += endBlock
        }
        return {}
    }

    function reset() {
        isReasoning = false
        toolUseByIndex = ({})
    }
}
