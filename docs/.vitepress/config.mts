import { defineConfig } from "vitepress";

export default defineConfig({
	base: process.env.DOCS_BASE ?? "/",
	title: "Anatomy",
	description: "Named sockets and hierarchical tags read from an element table, composed by priority. Plain Luau.",
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
			{
				text: "TODO",
				collapsed: true,
				items: [{ text: "API proposal (VMMO-92)", link: "/todo/vmmo92/apiProposal" }],
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
