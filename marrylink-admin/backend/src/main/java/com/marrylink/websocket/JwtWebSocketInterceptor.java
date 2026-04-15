package com.marrylink.websocket;

import com.marrylink.security.JwtTokenProvider;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.http.server.ServletServerHttpRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;

import javax.annotation.Resource;
import java.util.Map;

@Slf4j
@Component
public class JwtWebSocketInterceptor implements HandshakeInterceptor {

    @Resource
    private JwtTokenProvider jwtTokenProvider;

    @Override
    public boolean beforeHandshake(ServerHttpRequest request, ServerHttpResponse response,
                                    WebSocketHandler wsHandler, Map<String, Object> attributes) throws Exception {
        if (request instanceof ServletServerHttpRequest) {
            ServletServerHttpRequest servletRequest = (ServletServerHttpRequest) request;
            String token = servletRequest.getServletRequest().getParameter("token");

            if (token != null && !token.isEmpty()) {
                try {
                    // Validate token (with Redis check)
                    if (jwtTokenProvider.validateTokenWithRedis(token)) {
                        Long accountId = jwtTokenProvider.getAccountIdFromToken(token);
                        Long refId = jwtTokenProvider.getRefIdFromToken(token);
                        String userType = jwtTokenProvider.getUserTypeFromToken(token);

                        attributes.put("accountId", accountId);
                        attributes.put("refId", refId);
                        attributes.put("userType", userType);

                        log.info("[WebSocket] 握手认证成功: userType={}, refId={}", userType, refId);
                        return true;
                    }
                } catch (Exception e) {
                    log.warn("[WebSocket] Token验证失败: {}", e.getMessage());
                }
            }
            log.warn("[WebSocket] 握手认证失败: 缺少有效token");
            return false;
        }
        return false;
    }

    @Override
    public void afterHandshake(ServerHttpRequest request, ServerHttpResponse response,
                                WebSocketHandler wsHandler, Exception exception) {
        // No-op
    }
}
