//go:build generate
// +build generate

package main

import (
	"fmt"
	"path/filepath"

	"k8s.io/klog/v2"
)

func main() {
	// Paths
	apisPath := filepath.Join("pkg", "apis")
	clientsetPath := filepath.Join("pkg", "generated", "clientset")
	informersPath := filepath.Join("pkg", "generated", "informers")

	// Generate clientset
	if err := client_gen.Run(
		&client_gen.Generator{
			InputVersions:   []string{"topology/v1alpha1"},
			InputPackages:   []string{apisPath},
			OutputPackage:   clientsetPath,
			BoilerplatePath: "boilerplate.go.txt",
		},
	); err != nil {
		klog.Fatalf("Failed to generate clientset: %v", err)
	}

	// Generate informers
	if err := informer_gen.Run(
		&informer_gen.GeneratorArgs{
			VersionedClientSetPackage: fmt.Sprintf("%s/versioned", clientsetPath),
			InternalClientSetPackage:  fmt.Sprintf("%s/internalclientset", clientsetPath),
			ListerPackage:             fmt.Sprintf("%s/listers", informersPath),
			InformerPackage:           fmt.Sprintf("%s/externalversions", informersPath),
			InputDirectories:          []string{apisPath + "/topology/v1alpha1"},
			OutputPackagePath:         informersPath,
			BoilerplatePath:           "boilerplate.go.txt",
		},
	); err != nil {
		klog.Fatalf("Failed to generate informers: %v", err)
	}
}
