package com.concert.service;

import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.jwk.source.RemoteJWKSet;
import com.nimbusds.jose.proc.JWSKeySelector;
import com.nimbusds.jose.proc.JWSVerificationKeySelector;
import com.nimbusds.jose.proc.SecurityContext;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.proc.ConfigurableJWTProcessor;
import com.nimbusds.jwt.proc.DefaultJWTProcessor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URL;

@Service
public class CognitoJwtValidator {

    private static final Logger logger = LoggerFactory.getLogger(CognitoJwtValidator.class);
    
    @Value("${aws.cognito.user-pool-id:us-east-1_nTZpyinXc}")
    private String userPoolId;
    
    @Value("${aws.cognito.region:us-east-1}")
    private String region;
    
    private ConfigurableJWTProcessor<SecurityContext> jwtProcessor;
    
    public JWTClaimsSet validateToken(String token) {
        try {
            if (jwtProcessor == null) {
                initializeJwtProcessor();
            }
            
            // Validate and parse the JWT
            JWTClaimsSet claims = jwtProcessor.process(token, null);
            
            // Verify token use
            String tokenUse = claims.getStringClaim("token_use");
            if (!"id".equals(tokenUse) && !"access".equals(tokenUse)) {
                throw new IllegalArgumentException("Invalid token_use claim: " + tokenUse);
            }
            
            logger.debug("Successfully validated Cognito JWT for user: {}", claims.getSubject());
            return claims;
            
        } catch (Exception e) {
            logger.error("Failed to validate Cognito JWT", e);
            throw new IllegalArgumentException("Invalid Cognito JWT token", e);
        }
    }
    
    private void initializeJwtProcessor() throws Exception {
        String jwksUrl = String.format(
            "https://cognito-idp.%s.amazonaws.com/%s/.well-known/jwks.json",
            region, userPoolId
        );
        
        @SuppressWarnings("deprecation")
        JWKSource<SecurityContext> keySource = new RemoteJWKSet<>(new URL(jwksUrl));
        JWSAlgorithm expectedJWSAlg = JWSAlgorithm.RS256;
        JWSKeySelector<SecurityContext> keySelector = new JWSVerificationKeySelector<>(expectedJWSAlg, keySource);
        
        jwtProcessor = new DefaultJWTProcessor<>();
        jwtProcessor.setJWSKeySelector(keySelector);
        
        logger.info("Initialized Cognito JWT processor with pool: {}", userPoolId);
    }
    
    public String getUsernameFromToken(String token) {
        JWTClaimsSet claims = validateToken(token);
        // Cognito username is in 'cognito:username' claim
        try {
            return claims.getStringClaim("cognito:username");
        } catch (Exception e) {
            // Fallback to email or sub
            try {
                String email = claims.getStringClaim("email");
                return email != null ? email : claims.getSubject();
            } catch (Exception ex) {
                return claims.getSubject();
            }
        }
    }
    
    public String getEmailFromToken(String token) {
        JWTClaimsSet claims = validateToken(token);
        try {
            return claims.getStringClaim("email");
        } catch (Exception e) {
            return null;
        }
    }
    
    public String getSubFromToken(String token) {
        JWTClaimsSet claims = validateToken(token);
        return claims.getSubject(); // This is the Cognito user ID (sub)
    }
}
