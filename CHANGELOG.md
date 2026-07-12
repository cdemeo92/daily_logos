## [1.13.8](https://github.com/cdemeo92/daily_logos/compare/v1.13.7...v1.13.8) (2026-07-12)


### Bug Fixes

* update Dockerfile to set executable permissions for all binaries in releases and bin directories ([1a490ae](https://github.com/cdemeo92/daily_logos/commit/1a490ae65e6a360e409621e95dc4db4711740ad0))

## [1.13.7](https://github.com/cdemeo92/daily_logos/compare/v1.13.6...v1.13.7) (2026-07-12)


### Bug Fixes

* update Dockerfile to ensure proper execution of daily_logos with error handling ([6ac05b5](https://github.com/cdemeo92/daily_logos/commit/6ac05b55e9f84db81d54541e42fcb2d942175b8f))

## [1.13.6](https://github.com/cdemeo92/daily_logos/compare/v1.13.5...v1.13.6) (2026-07-12)


### Bug Fixes

* update deploy job to use environment variable for Render deployment hook ([5fa11b8](https://github.com/cdemeo92/daily_logos/commit/5fa11b8f2009347190051f309d183a7cc8ac7cfb))

## [1.13.5](https://github.com/cdemeo92/daily_logos/compare/v1.13.4...v1.13.5) (2026-07-12)


### Bug Fixes

* add lifecycle block to ignore changes for maintenance_mode in render_web_service resource ([2729a0d](https://github.com/cdemeo92/daily_logos/commit/2729a0dc4d5278760eeb6723fd103a42a88810f3))

## [1.13.4](https://github.com/cdemeo92/daily_logos/compare/v1.13.3...v1.13.4) (2026-07-12)


### Bug Fixes

* remove migrations job from CI workflow and update deploy job dependencies ([5942162](https://github.com/cdemeo92/daily_logos/commit/5942162d9d75e5b896e337089f3bab57098e054b))

## [1.13.3](https://github.com/cdemeo92/daily_logos/compare/v1.13.2...v1.13.3) (2026-07-12)


### Bug Fixes

* restore and configure migrations job in CI workflow ([8037fba](https://github.com/cdemeo92/daily_logos/commit/8037fba64900b23367e43c9068a3663844074799))

## [1.13.2](https://github.com/cdemeo92/daily_logos/compare/v1.13.1...v1.13.2) (2026-07-12)


### Bug Fixes

* update CI workflow by commenting out migrations job and removing build artifact upload ([eb1e784](https://github.com/cdemeo92/daily_logos/commit/eb1e784dae13c89068bdf3e74ad9e5a738ba7240))
* update deploy job dependencies by removing migrations requirement ([fb4b7b5](https://github.com/cdemeo92/daily_logos/commit/fb4b7b5ffad84af5aaf6a29b022861a16050aa00))

## [1.13.1](https://github.com/cdemeo92/daily_logos/compare/v1.13.0...v1.13.1) (2026-07-12)


### Bug Fixes

* enhance CI workflow by adding build artifact upload for migrations and adjusting job dependencies ([927479d](https://github.com/cdemeo92/daily_logos/commit/927479d01cfca08be787a3d946062047acb5729a))

# [1.13.0](https://github.com/cdemeo92/daily_logos/compare/v1.12.0...v1.13.0) (2026-07-12)


### Features

* update CI workflow to build DATABASE_URL dynamically and modify migration job dependencies ([b7470df](https://github.com/cdemeo92/daily_logos/commit/b7470df46a65e9d6de0f5bacb6c9ad348de44bf0))

# [1.12.0](https://github.com/cdemeo92/daily_logos/compare/v1.11.0...v1.12.0) (2026-07-12)


### Features

* update CI workflow and Terraform configuration to use DATABASE_URL from secrets ([4c5da10](https://github.com/cdemeo92/daily_logos/commit/4c5da10ddc824504e6c5902a19838a53ad1e3db9))

# [1.11.0](https://github.com/cdemeo92/daily_logos/compare/v1.10.0...v1.11.0) (2026-07-12)


### Features

* add migrations job to CI workflow and update deployment dependencies ([96b4b53](https://github.com/cdemeo92/daily_logos/commit/96b4b535d2fccb6cf7c20608f8ac2b50039f14a8))

# [1.10.0](https://github.com/cdemeo92/daily_logos/compare/v1.9.0...v1.10.0) (2026-07-12)


### Features

* update lifecycle block in render_web_service to ignore all changes ([48ef1d5](https://github.com/cdemeo92/daily_logos/commit/48ef1d58304ddb0ddfbf3785f1cd367171d829b8))

# [1.9.0](https://github.com/cdemeo92/daily_logos/compare/v1.8.0...v1.9.0) (2026-07-12)


### Features

* add lifecycle block to render_web_service resource to ignore specific changes ([c68e8f9](https://github.com/cdemeo92/daily_logos/commit/c68e8f9d61cdcfb1e19ce4828027be551823d2a6))

# [1.8.0](https://github.com/cdemeo92/daily_logos/compare/v1.7.0...v1.8.0) (2026-07-12)


### Features

* implement database migration functionality and update CI workflow ([f4eb066](https://github.com/cdemeo92/daily_logos/commit/f4eb066644943a654fa50f79db4fb503838ad823))

# [1.7.0](https://github.com/cdemeo92/daily_logos/compare/v1.6.2...v1.7.0) (2026-07-11)


### Features

* implement migrations job in CI workflow with Terraform integration ([6a298d1](https://github.com/cdemeo92/daily_logos/commit/6a298d142abb61dd3e931a1a111eafac8bc3714e))

## [1.6.2](https://github.com/cdemeo92/daily_logos/compare/v1.6.1...v1.6.2) (2026-07-11)


### Bug Fixes

* update cache action version to v6 and change render plan to free ([53e259e](https://github.com/cdemeo92/daily_logos/commit/53e259e7334303aee39ffa4ac17858e649154845))

## [1.6.1](https://github.com/cdemeo92/daily_logos/compare/v1.6.0...v1.6.1) (2026-07-11)


### Bug Fixes

* update render plan from hobby to starter in CI workflow ([886a317](https://github.com/cdemeo92/daily_logos/commit/886a317aa9af320153a11fe89523790839131d3b))

# [1.6.0](https://github.com/cdemeo92/daily_logos/compare/v1.5.1...v1.6.0) (2026-07-11)


### Bug Fixes

* remove migrations dependency from deploy job in CI workflow ([e987f28](https://github.com/cdemeo92/daily_logos/commit/e987f282e81013da38ebfd152f9126e30e8e5fa4))


### Features

* add caching step to CI workflow and output app_database_url in Terraform ([f44493f](https://github.com/cdemeo92/daily_logos/commit/f44493f3cefd963bfe93e3b671ab932859d92886))

## [1.5.1](https://github.com/cdemeo92/daily_logos/compare/v1.5.0...v1.5.1) (2026-07-11)


### Bug Fixes

* update migrations job dependencies and add SECRET_KEY_BASE to environment ([a668790](https://github.com/cdemeo92/daily_logos/commit/a668790fc18fdee22b11eb3421e6a466baa89ddd))

# [1.5.0](https://github.com/cdemeo92/daily_logos/compare/v1.4.3...v1.5.0) (2026-07-11)


### Features

* add migrations job to CI workflow for running Ecto migrations ([2dc45a6](https://github.com/cdemeo92/daily_logos/commit/2dc45a6500f3c7fd090156dba7ca3666292ea897))

## [1.4.3](https://github.com/cdemeo92/daily_logos/compare/v1.4.2...v1.4.3) (2026-07-11)


### Bug Fixes

* update retention days for terraform state and modify example render credentials ([d335b19](https://github.com/cdemeo92/daily_logos/commit/d335b1960c73a5f9a42d83828f1b2abfd4089f97))

## [1.4.2](https://github.com/cdemeo92/daily_logos/compare/v1.4.1...v1.4.2) (2026-07-11)


### Bug Fixes

* remove default value for cloudflare_api_token in variables.tf ([e1efab4](https://github.com/cdemeo92/daily_logos/commit/e1efab4a91d00a5bcd9fdbdda72d75b4f81bb8aa))

## [1.4.1](https://github.com/cdemeo92/daily_logos/compare/v1.4.0...v1.4.1) (2026-07-11)


### Bug Fixes

* update image URL structure in render_web_service and set default Cloudflare API token ([fae0494](https://github.com/cdemeo92/daily_logos/commit/fae04947899db91baaa9c71a72a39fdd04c4e6c4))

# [1.4.0](https://github.com/cdemeo92/daily_logos/compare/v1.3.0...v1.4.0) (2026-07-11)


### Features

* add render_owner_id variable and update Terraform configuration ([f666486](https://github.com/cdemeo92/daily_logos/commit/f6664867b4f8ae8c5837aa30681289060ccba298))

# [1.3.0](https://github.com/cdemeo92/daily_logos/compare/v1.2.3...v1.3.0) (2026-07-11)


### Features

* enhance CI workflow with Terraform state management and update Cloudflare page rule actions ([14722c3](https://github.com/cdemeo92/daily_logos/commit/14722c3f80ff3a986ac77198b835290d13ce4f63))

## [1.2.3](https://github.com/cdemeo92/daily_logos/compare/v1.2.2...v1.2.3) (2026-07-11)


### Bug Fixes

* update Cloudflare DNS records and page rules to use variable for zone name ([c2e9514](https://github.com/cdemeo92/daily_logos/commit/c2e95147c1a055f11e378bb60b719efcff597ba4))

## [1.2.2](https://github.com/cdemeo92/daily_logos/compare/v1.2.1...v1.2.2) (2026-07-11)


### Bug Fixes

* update DATABASE_URL in render_web_service env_vars to use dynamic Supabase connection string ([c4e9e9b](https://github.com/cdemeo92/daily_logos/commit/c4e9e9b0f8e017f4c651c905d2e1c3622fbefdc1))

## [1.2.1](https://github.com/cdemeo92/daily_logos/compare/v1.2.0...v1.2.1) (2026-07-11)


### Bug Fixes

* rename deploy job in CI workflow and remove unnecessary dependency in Terraform configuration ([9fae8ed](https://github.com/cdemeo92/daily_logos/commit/9fae8eda35a4f788eede24db81acaffabfe98f48))

# [1.2.0](https://github.com/cdemeo92/daily_logos/compare/v1.1.0...v1.2.0) (2026-07-11)


### Features

* update Terraform configuration for Render and Cloudflare settings; add image_tag variable ([441f0ea](https://github.com/cdemeo92/daily_logos/commit/441f0eadcbc4c1efef0b680ec5f4c52615d76b40))

# [1.1.0](https://github.com/cdemeo92/daily_logos/compare/v1.0.1...v1.1.0) (2026-07-11)


### Features

* add Terraform configuration and GitHub Actions workflows for deployment ([cf94e0b](https://github.com/cdemeo92/daily_logos/commit/cf94e0b0c20806c562c924beaba526660d918ac6))

## [1.0.1](https://github.com/cdemeo92/daily_logos/compare/v1.0.0...v1.0.1) (2026-07-10)


### Bug Fixes

* update Dependabot configuration to limit open pull requests and group dependencies; modify Dockerfile to use existing user ([320665b](https://github.com/cdemeo92/daily_logos/commit/320665ba341dc5c224ea3fbab11ac56f03bc4781))

# 1.0.0 (2026-07-10)


### Bug Fixes

* enhance locale detection logic and add corresponding tests ([9c53c2b](https://github.com/cdemeo92/daily_logos/commit/9c53c2b3ce61714116af28bbdb71195c75979794))
* fix parsing in seeds ([58b14dd](https://github.com/cdemeo92/daily_logos/commit/58b14dd5fbc93339d6578967ced7bf86de4e2be9))


### Features

* add About and Support pages with corresponding routes and links ([e494c15](https://github.com/cdemeo92/daily_logos/commit/e494c1544f4464002c5c70ffa0dbbfb882cfcae3))
* add AdSlot component and integrate it into the footer layout ([5579d49](https://github.com/cdemeo92/daily_logos/commit/5579d49a29f60e4cc9cf21457294dfa64806fa68))
* add Buy Me a Coffee support and enhance feedback messaging ([dbcc7c5](https://github.com/cdemeo92/daily_logos/commit/dbcc7c56e326bd9d560662091002fcbdf3c322b9))
* add data seeding functionality with CSV support and update test aliases ([edec200](https://github.com/cdemeo92/daily_logos/commit/edec2003be40e12eda7551de1000f589fe86c896))
* add Dependabot configuration and enable auto-merge for PRs ([8512435](https://github.com/cdemeo92/daily_logos/commit/8512435c80204f95209357b5c81404850c01dc8e))
* add dynamic date display and month translations to home page ([fce570e](https://github.com/cdemeo92/daily_logos/commit/fce570eaa5e2843eb62a08e1f51db0e5040e2647))
* add feedback page with Google Form integration and placeholder ([61e2703](https://github.com/cdemeo92/daily_logos/commit/61e2703ad779ac2068f24c195adbbd41a1d8ba48))
* add locale toggle component to switch between supported locales ([820a43d](https://github.com/cdemeo92/daily_logos/commit/820a43d1f650721847f814116951cd8daed9a8e0))
* add mix compile step before building release ([a0ae31f](https://github.com/cdemeo92/daily_logos/commit/a0ae31fa994748a76cfd5776550121f5a9a1983b))
* add quote api and enhance error handling ([f8e315d](https://github.com/cdemeo92/daily_logos/commit/f8e315dbb6e0677f76a1663192ffde124bb8b631))
* configure Erlang/Elixir versions in CI workflow ([b99f956](https://github.com/cdemeo92/daily_logos/commit/b99f95607c356df56dc679b1d46b865c0535aab1))
* enhance CI workflow with improved caching and asset setup ([fe9c720](https://github.com/cdemeo92/daily_logos/commit/fe9c720b5c0aed6270c61c9ee55bce385b93ceba))
* enhance locale toggle functionality with JavaScript event handling ([8d555d3](https://github.com/cdemeo92/daily_logos/commit/8d555d3d9032ef2498773881e37dfc92aff2a71f))
* implement daily quote loading with error handling and localization support ([0836969](https://github.com/cdemeo92/daily_logos/commit/08369692a3e7f749fa86a1cc5f57c8b95c927707))
* implement locale management with session and accept-language header support ([c55ad75](https://github.com/cdemeo92/daily_logos/commit/c55ad75bae9abddffa7adeae548aa1f3d1cf6868))
* implement locale management with session support and add integration/unit tests ([3f21f9a](https://github.com/cdemeo92/daily_logos/commit/3f21f9aebda821b82e29755411e8bd940657f3c0))
* implement quotes management with CRUD operations and integration tests ([bf96e0c](https://github.com/cdemeo92/daily_logos/commit/bf96e0c9c8fc731dd5a761a6f72e61411b3b21e2))
* implement SEO metadata management and add sitemap support ([d06112e](https://github.com/cdemeo92/daily_logos/commit/d06112eec7834cc0b60facb16ebf07f512a03b9c))
* initial commit ([89b00e2](https://github.com/cdemeo92/daily_logos/commit/89b00e2dbca1837e2d2c6042a80a463434cd13bf))
* set up CI/CD pipeline with Docker support and semantic release configuration ([b0acab2](https://github.com/cdemeo92/daily_logos/commit/b0acab2e54457fec4c31e74ecb2eb8cdcacb3ba1))
