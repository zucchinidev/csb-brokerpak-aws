package acceptance_tests_test

import (
	"csbbrokerpakaws/acceptance-tests/helpers/cf"
	"csbbrokerpakaws/acceptance-tests/helpers/random"
	"time"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("Error Messages", Label("errormessages"), func() {
	When("the create-service command fails immediately", func() {
		It("prints a useful error message", func() {
			name := random.Name(random.WithPrefix("error"))
			defer cf.Run("delete-service", "-f", name)

			session := cf.Start("create-service", "csb-aws-mysql", "small", name, "-c", `{"region":"bogus"}`)
			Eventually(session, time.Minute).Should(Exit(1))
			Expect(session.Out).To(Say(`FAILED\n`))
			Expect(session.Err).To(Say(`Service broker error: 1 error\(s\) occurred:.*region: region must be one of the following:( "\S+",?)+\n$`))
		})
	})

	When("the service creation fail asynchronously", func() {
		It("puts a useful error message in the service description", func() {
			name := random.Name(random.WithPrefix("error"))
			defer cf.Run("delete-service", "-f", name)

			session := cf.Start("create-service", "csb-aws-mysql", "small", name, "-c", `{"instance_class":"bogus"}`)
			Eventually(session, time.Minute).Should(Exit(0))

			Eventually(func() string {
				stdout, _ := cf.Run("service", name)
				return stdout
			}, 10*time.Minute, 10*time.Second).Should(MatchRegexp(`status:\s+create failed`))

			stdout, _ := cf.Run("service", name)
			Expect(stdout).To(MatchRegexp(`message:\s+provision failed: Error: Error creating DB Instance: InvalidParameterValue: Invalid DB Instance class: bogus`))
		})
	})
})
