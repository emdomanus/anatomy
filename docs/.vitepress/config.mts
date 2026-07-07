import { defineConfig } from "vitepress";

export default defineConfig({
	base: process.env.DOCS_BASE ?? "/",
	title: "Anatomy",
	description: "Renderable anatomy, socket, tag, and mounting primitives for Roblox.",
	cleanUrls: true,
	themeConfig: {
		nav: [
			{ text: "Guide", link: "/" },
			{ text: "Types", link: "/types" },
			{ text: "Architecture", link: "/ARCHITECTURE" },
		],
		sidebar: [
			{
				text: "Anatomy",
				items: [
					{ text: "Overview", link: "/" },
					{ text: "Types", link: "/types" },
					{ text: "Architecture", link: "/ARCHITECTURE" },
				],
			},
		],
		search: {
			provider: "local",
		},
		outline: {
			level: [2, 3],
		},
		socialLinks: [
			{ icon: "github", link: "https://github.com/emdomanus/anatomy" },
		],
		editLink: {
			pattern: "https://github.com/emdomanus/anatomy/edit/main/docs/:path",
			text: "Edit this page on GitHub",
		},
	},
});
