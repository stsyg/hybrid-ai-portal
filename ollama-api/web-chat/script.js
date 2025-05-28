class OllamaChat {
    constructor() {
        this.apiUrl = '/api';
        this.currentModel = null;
        this.messages = [];
        this.isGenerating = false;
        
        this.initializeElements();
        this.attachEventListeners();
        this.loadModels();
        this.checkConnection();
    }

    initializeElements() {
        this.chatMessages = document.getElementById('chat-messages');
        this.chatInput = document.getElementById('chat-input');
        this.sendButton = document.getElementById('send-button');
        this.modelSelect = document.getElementById('model-select');
        this.refreshModelsButton = document.getElementById('refresh-models');
        this.statusElement = document.getElementById('status');
        this.connectionStatus = document.getElementById('connection-status');
    }

    attachEventListeners() {
        this.sendButton.addEventListener('click', () => this.sendMessage());
        this.chatInput.addEventListener('keydown', (e) => this.handleInputKeydown(e));
        this.chatInput.addEventListener('input', () => this.autoResizeTextarea());
        this.modelSelect.addEventListener('change', () => this.selectModel());
        this.refreshModelsButton.addEventListener('click', () => this.loadModels());
    }

    handleInputKeydown(e) {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            this.sendMessage();
        }
    }

    autoResizeTextarea() {
        this.chatInput.style.height = 'auto';
        this.chatInput.style.height = Math.min(this.chatInput.scrollHeight, 120) + 'px';
    }

    async checkConnection() {
        try {
            const response = await fetch(`${this.apiUrl}/tags`);
            if (response.ok) {
                this.updateConnectionStatus(true);
            } else {
                this.updateConnectionStatus(false);
            }
        } catch (error) {
            this.updateConnectionStatus(false);
        }
    }

    updateConnectionStatus(connected) {
        if (connected) {
            this.connectionStatus.textContent = '🟢';
            this.connectionStatus.title = 'Connected to Ollama API';
        } else {
            this.connectionStatus.textContent = '🔴';
            this.connectionStatus.title = 'Disconnected from Ollama API';
        }
    }

    async loadModels() {
        try {
            this.updateStatus('Loading models...');
            this.modelSelect.disabled = true;
            this.modelSelect.innerHTML = '<option value="">Loading models...</option>';

            const response = await fetch(`${this.apiUrl}/tags`);
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();
            this.populateModelSelect(data.models || []);
            this.updateConnectionStatus(true);
            this.updateStatus('Ready');
        } catch (error) {
            console.error('Error loading models:', error);
            this.modelSelect.innerHTML = '<option value="">Failed to load models</option>';
            this.updateConnectionStatus(false);
            this.updateStatus('Error: Failed to load models');
            this.showErrorMessage('Failed to load models. Please check your connection to the Ollama API.');
        } finally {
            this.modelSelect.disabled = false;
        }
    }

    populateModelSelect(models) {
        this.modelSelect.innerHTML = '<option value="">Select a model...</option>';
        
        if (models.length === 0) {
            this.modelSelect.innerHTML += '<option value="">No models available</option>';
            return;
        }

        models.forEach(model => {
            const option = document.createElement('option');
            option.value = model.name;
            option.textContent = `${model.name} (${this.formatSize(model.size)})`;
            this.modelSelect.appendChild(option);
        });

        // Auto-select first model if available
        if (models.length > 0) {
            this.modelSelect.value = models[0].name;
            this.selectModel();
        }
    }

    formatSize(bytes) {
        if (bytes === 0) return '0 B';
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
    }

    selectModel() {
        this.currentModel = this.modelSelect.value;
        this.sendButton.disabled = !this.currentModel || this.isGenerating;
        
        if (this.currentModel) {
            this.updateStatus(`Model: ${this.currentModel}`);
        } else {
            this.updateStatus('Select a model to start chatting');
        }
    }

    updateStatus(message) {
        this.statusElement.textContent = message;
    }

    async sendMessage() {
        const message = this.chatInput.value.trim();
        if (!message || !this.currentModel || this.isGenerating) return;

        // Add user message to chat
        this.addMessage('user', message);
        this.chatInput.value = '';
        this.autoResizeTextarea();

        // Disable input while generating
        this.setGenerating(true);

        try {
            await this.generateResponse(message);
        } catch (error) {
            console.error('Error generating response:', error);
            this.addMessage('assistant', 'Sorry, I encountered an error while generating a response. Please try again.');
        } finally {
            this.setGenerating(false);
        }
    }

    setGenerating(generating) {
        this.isGenerating = generating;
        this.sendButton.disabled = generating || !this.currentModel;
        this.chatInput.disabled = generating;
        this.modelSelect.disabled = generating;
        
        if (generating) {
            this.updateStatus('Generating response...');
            this.showTypingIndicator();
        } else {
            this.updateStatus(`Model: ${this.currentModel}`);
            this.hideTypingIndicator();
        }
    }

    async generateResponse(prompt) {
        const requestBody = {
            model: this.currentModel,
            prompt: prompt,
            stream: true
        };

        const response = await fetch(`${this.apiUrl}/generate`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(requestBody)
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const reader = response.body.getReader();
        const decoder = new TextDecoder();
        let assistantMessage = this.addMessage('assistant', '');
        let fullResponse = '';

        try {
            while (true) {
                const { done, value } = await reader.read();
                if (done) break;

                const chunk = decoder.decode(value);
                const lines = chunk.split('\n').filter(line => line.trim());

                for (const line of lines) {
                    try {
                        const data = JSON.parse(line);
                        if (data.response) {
                            fullResponse += data.response;
                            this.updateMessage(assistantMessage, fullResponse);
                        }
                    } catch (e) {
                        // Ignore JSON parsing errors for incomplete chunks
                    }
                }
            }
        } finally {
            reader.releaseLock();
        }

        // Ensure the message is properly formatted with markdown
        this.updateMessage(assistantMessage, fullResponse, true);
    }

    addMessage(role, content) {
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${role}`;
        
        const avatar = document.createElement('div');
        avatar.className = 'message-avatar';
        avatar.textContent = role === 'user' ? '👤' : '🤖';
        
        const contentDiv = document.createElement('div');
        contentDiv.className = 'message-content';
        
        if (role === 'assistant' && content === '') {
            // For empty assistant messages, we'll update them later
            contentDiv.innerHTML = '<span class="typing-indicator">Thinking...</span>';
        } else {
            contentDiv.innerHTML = this.formatMessage(content);
        }
        
        messageDiv.appendChild(avatar);
        messageDiv.appendChild(contentDiv);
        
        this.chatMessages.appendChild(messageDiv);
        this.scrollToBottom();
        
        return messageDiv;
    }

    updateMessage(messageElement, content, final = false) {
        const contentDiv = messageElement.querySelector('.message-content');
        if (final) {
            // Final update with proper markdown formatting
            contentDiv.innerHTML = this.formatMessage(content);
            // Highlight code blocks
            contentDiv.querySelectorAll('pre code').forEach(block => {
                if (window.Prism) {
                    window.Prism.highlightElement(block);
                }
            });
        } else {
            // Streaming update
            contentDiv.textContent = content;
        }
        this.scrollToBottom();
    }

    formatMessage(content) {
        if (!content) return '';
        
        // Use marked.js to parse markdown if available
        if (window.marked) {
            return window.marked.parse(content);
        }
        
        // Basic formatting fallback
        return content
            .replace(/\n/g, '<br>')
            .replace(/`([^`]+)`/g, '<code>$1</code>')
            .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
            .replace(/\*([^*]+)\*/g, '<em>$1</em>');
    }

    showTypingIndicator() {
        // The typing indicator is handled by the "Thinking..." text in empty assistant messages
    }

    hideTypingIndicator() {
        // The typing indicator is replaced when we update the message content
    }

    showErrorMessage(message) {
        const errorDiv = document.createElement('div');
        errorDiv.className = 'error-message';
        errorDiv.textContent = message;
        this.chatMessages.appendChild(errorDiv);
        this.scrollToBottom();
        
        // Auto-remove error message after 5 seconds
        setTimeout(() => {
            if (errorDiv.parentNode) {
                errorDiv.parentNode.removeChild(errorDiv);
            }
        }, 5000);
    }

    scrollToBottom() {
        this.chatMessages.scrollTop = this.chatMessages.scrollHeight;
    }
}

// Initialize the chat application when the DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new OllamaChat();
});

// Add some helpful keyboard shortcuts
document.addEventListener('keydown', (e) => {
    // Ctrl/Cmd + K to focus on input
    if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        document.getElementById('chat-input').focus();
    }
    
    // Escape to blur input
    if (e.key === 'Escape') {
        document.getElementById('chat-input').blur();
    }
});
