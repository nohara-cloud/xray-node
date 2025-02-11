package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var (
	version  = "0.9.10"
	codename = "nboard-node"
	intro    = "The backend of nboard panel, powered by Xray"
)

func init() {
	rootCmd.AddCommand(&cobra.Command{
		Use:   "version",
		Short: "Print current version of XrayR",
		Run: func(cmd *cobra.Command, args []string) {
			showVersion()
		},
	})
}

func showVersion() {
	fmt.Printf("%s %s (%s) \n", codename, version, intro)
}
