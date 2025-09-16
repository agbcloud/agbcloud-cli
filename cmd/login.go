// Copyright 2025 AgbCloud CLI Contributors
// SPDX-License-Identifier: Apache-2.0

package cmd

import (
	"context"
	"fmt"
	"time"

	"github.com/pkg/browser"
	"github.com/spf13/cobra"

	"github.com/agbcloud/agbcloud-cli/internal/auth"
	"github.com/agbcloud/agbcloud-cli/internal/client"
	"github.com/agbcloud/agbcloud-cli/internal/config"
)

var LoginCmd = &cobra.Command{
	Use:   "login",
	Short: "Log in to AgbCloud",
	Long:  "Authenticate with AgbCloud using OAuth in your browser",
	Args:  cobra.NoArgs,
	RunE: func(cmd *cobra.Command, args []string) error {
		return runLogin(cmd)
	},
}

func init() {
	// No flags needed for login command
}

func runLogin(cmd *cobra.Command) error {
	fmt.Println("🔐 Starting AgbCloud authentication...")

	// Create client configuration for OAuth
	cfg := config.DefaultConfig()

	apiClient := client.NewFromConfig(cfg)

	// Get default callback port (port selection is handled automatically by server)
	defaultPort := auth.GetCallbackPort()
	fmt.Printf("📡 Default callback port: %s\n", defaultPort)

	// Create context with timeout for OAuth request
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	fmt.Println("🌐 Requesting OAuth login URL...")

	// First call - Get the OAuth URL without localhostPort parameter
	response, httpResp, err := apiClient.OAuthAPI.GetLoginProviderURL(ctx, fmt.Sprintf("http://localhost:%s", defaultPort), "CLI", "GOOGLE_LOCALHOST")
	if err != nil {
		if apiErr, ok := err.(*client.GenericOpenAPIError); ok {
			fmt.Printf("❌ API Error: %s\n", apiErr.Error())
			if httpResp != nil {
				fmt.Printf("📊 Status Code: %d\n", httpResp.StatusCode)
			}
			if len(apiErr.Body()) > 0 {
				fmt.Printf("📄 Response Body: %s\n", string(apiErr.Body()))
			}
			return fmt.Errorf("failed to get OAuth URL: %s", apiErr.Error())
		}
		return fmt.Errorf("network error: %v", err)
	}

	// Verify we got a successful response
	if !response.Success {
		return fmt.Errorf("OAuth request failed: %s", response.Code)
	}

	// Check if default port is available
	var finalPort string
	var finalResponse client.OAuthLoginProviderResponse

	if !auth.IsPortOccupied(defaultPort) {
		// Default port is available, use it
		finalPort = defaultPort
		finalResponse = response
		fmt.Printf("✅ Default port %s is available\n", defaultPort)
	} else {
		// Default port is occupied, try alternative ports
		fmt.Printf("⚠️  Default port %s is occupied, trying alternative ports...\n", defaultPort)

		if response.Data.AlternativePorts == "" {
			return fmt.Errorf("default port %s is occupied and no alternative ports provided", defaultPort)
		}

		// Select an available port from alternatives
		selectedPort, err := auth.SelectAvailablePort(defaultPort, response.Data.AlternativePorts)
		if err != nil {
			fmt.Printf("❌ Port selection failed:\n")
			fmt.Printf("   Default port %s is occupied\n", defaultPort)
			if response.Data.AlternativePorts != "" {
				fmt.Printf("   Alternative ports provided: %s\n", response.Data.AlternativePorts)
				fmt.Printf("   All alternative ports are also occupied\n")
				fmt.Printf("💡 Please free up one of these ports and try again\n")
			} else {
				fmt.Printf("   No alternative ports provided by server\n")
			}
			return fmt.Errorf("failed to find available port: %v", err)
		}

		fmt.Printf("🔄 Using alternative port: %s\n", selectedPort)

		// Make second API call with the selected port
		secondResponse, secondHttpResp, err := apiClient.OAuthAPI.GetLoginProviderURLWithPort(ctx, fmt.Sprintf("http://localhost:%s", selectedPort), "CLI", "GOOGLE_LOCALHOST", selectedPort)
		if err != nil {
			if apiErr, ok := err.(*client.GenericOpenAPIError); ok {
				fmt.Printf("❌ API Error on second call: %s\n", apiErr.Error())
				if secondHttpResp != nil {
					fmt.Printf("📊 Status Code: %d\n", secondHttpResp.StatusCode)
				}
				if len(apiErr.Body()) > 0 {
					fmt.Printf("📄 Response Body: %s\n", string(apiErr.Body()))
				}
				return fmt.Errorf("failed to get OAuth URL with alternative port: %s", apiErr.Error())
			}
			return fmt.Errorf("network error on second call: %v", err)
		}

		if !secondResponse.Success {
			return fmt.Errorf("OAuth request with alternative port failed: %s", secondResponse.Code)
		}

		finalPort = selectedPort
		finalResponse = secondResponse
	}

	if finalResponse.Data.InvokeURL == "" {
		return fmt.Errorf("received empty OAuth URL from server")
	}

	fmt.Println("✅ Successfully retrieved OAuth URL!")
	fmt.Printf("📋 Request ID: %s\n", finalResponse.RequestID)
	fmt.Printf("🔍 Trace ID: %s\n", finalResponse.TraceID)
	fmt.Printf("📡 Final callback port: %s\n", finalPort)
	fmt.Println()

	// Start local callback server
	fmt.Printf("🚀 Starting local callback server on port %s...\n", finalPort)

	// Create context for callback server with longer timeout
	callbackCtx, callbackCancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer callbackCancel()

	// Start callback server in background
	codeChan := make(chan string, 1)
	errChan := make(chan error, 1)

	go func() {
		code, err := auth.StartCallbackServer(callbackCtx, finalPort)
		if err != nil {
			errChan <- err
			return
		}
		codeChan <- code
	}()

	// Give server time to start
	time.Sleep(100 * time.Millisecond)

	// Display the URL and open browser
	fmt.Println("🔗 OAuth URL:")
	fmt.Printf("  %s\n\n", finalResponse.Data.InvokeURL)

	fmt.Println("🌐 Opening the browser for authentication...")
	fmt.Println()
	fmt.Println("If the browser doesn't open automatically, please copy and paste the URL above.")

	err = browser.OpenURL(finalResponse.Data.InvokeURL)
	if err != nil {
		fmt.Printf("⚠️  Failed to open browser automatically: %v\n", err)
		fmt.Println("💡 Please copy the URL above and paste it into your browser to complete authentication.")
	} else {
		fmt.Println("✅ Browser opened successfully!")
	}

	fmt.Println("📝 Please complete the authentication process in your browser.")
	fmt.Printf("🔄 Waiting for callback on http://localhost:%s/callback...\n", finalPort)

	// Wait for callback
	select {
	case code := <-codeChan:
		fmt.Println("✅ Authentication successful!")
		fmt.Printf("🔑 Received authorization code: %s...\n", code[:min(len(code), 20)])

		// Now call LoginTranslate to exchange code for access token
		fmt.Println("🔄 Exchanging authorization code for access token...")

		// Create context for LoginTranslate request
		translateCtx, translateCancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer translateCancel()

		translateResponse, translateHttpResp, err := apiClient.OAuthAPI.LoginTranslateWithPort(translateCtx, "CLI", "GOOGLE_LOCALHOST", code, finalPort)
		if err != nil {
			if apiErr, ok := err.(*client.GenericOpenAPIError); ok {
				fmt.Printf("❌ LoginTranslate API Error: %s\n", apiErr.Error())
				if translateHttpResp != nil {
					fmt.Printf("📊 Status Code: %d\n", translateHttpResp.StatusCode)
				}
				if len(apiErr.Body()) > 0 {
					fmt.Printf("📄 Response Body: %s\n", string(apiErr.Body()))
				}
				return fmt.Errorf("failed to exchange code for token: %s", apiErr.Error())
			}
			return fmt.Errorf("network error during token exchange: %v", err)
		}

		// Display detailed response information
		fmt.Println("\n🎯 LoginTranslate Response Details:")
		fmt.Printf("📊 HTTP Status Code: %d\n", translateHttpResp.StatusCode)
		fmt.Printf("✅ Success: %v\n", translateResponse.Success)
		fmt.Printf("📝 Code: %s\n", translateResponse.Code)
		fmt.Printf("📋 Request ID: %s\n", translateResponse.RequestID)
		fmt.Printf("🔍 Trace ID: %s\n", translateResponse.TraceID)
		fmt.Printf("🌐 HTTP Status Code (from response): %d\n", translateResponse.HTTPStatusCode)

		if translateResponse.Success {
			fmt.Println("\n🔑 Authentication Token Information:")
			if translateResponse.Data.LoginToken != "" {
				fmt.Printf("🎫 Login Token: %s\n", translateResponse.Data.LoginToken)
			} else {
				fmt.Println("⚠️  Login Token: (empty)")
			}
			if translateResponse.Data.SessionId != "" {
				fmt.Printf("🆔 Session ID: %s\n", translateResponse.Data.SessionId)
			} else {
				fmt.Println("⚠️  Session ID: (empty)")
			}
			if translateResponse.Data.KeepAliveToken != "" {
				fmt.Printf("🔄 Keep Alive Token: %s", translateResponse.Data.KeepAliveToken)
			} else {
				fmt.Println("⚠️  Keep Alive Token: (empty)")
			}

			// Save tokens to configuration
			fmt.Println("\n💾 Saving authentication tokens...")

			config, err := config.GetConfig()
			if err != nil {
				fmt.Printf("⚠️  Warning: Failed to load config: %v\n", err)
				fmt.Println("🎉 You are logged in, but tokens were not saved to config file.")
				return nil
			}

			err = config.SaveTokens(
				translateResponse.Data.LoginToken,
				translateResponse.Data.SessionId,
				translateResponse.Data.KeepAliveToken,
				translateResponse.Data.ExpiresAt,
			)
			if err != nil {
				fmt.Printf("⚠️  Warning: Failed to save tokens: %v\n", err)
				fmt.Println("🎉 You are logged in, but tokens were not saved to config file.")
				return nil
			}

			fmt.Println("✅ Authentication tokens saved successfully!")
			fmt.Println("\n🎉 You are now logged in to AgbCloud!")
		} else {
			fmt.Printf("\n❌ Token exchange failed: %s\n", translateResponse.Code)
			return fmt.Errorf("token exchange was not successful")
		}

		return nil
	case err := <-errChan:
		return fmt.Errorf("authentication failed: %v", err)
	case <-callbackCtx.Done():
		return fmt.Errorf("authentication timeout: please try again")
	}
}

// min returns the minimum of two integers
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
