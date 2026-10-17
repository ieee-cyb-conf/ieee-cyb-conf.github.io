# Regression: GitHub Pages fix (no gitlink/submodule, workflow valid, clean-clone Jekyll build, live preview)
import os
import shutil
import subprocess
import pytest
import requests
import yaml

REPO = "/app"
FRONT_URL = None
with open("/app/frontend/.env") as f:
    for line in f:
        if line.startswith("REACT_APP_BACKEND_URL="):
            FRONT_URL = line.split("=", 1)[1].strip().rstrip("/")


def git(*args, cwd=REPO):
    return subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True, check=True).stdout


# Git index: no gitlinks, no .gitmodules, cybconf tracked as files
class TestGitIndex:
    def test_no_gitlink_in_index(self):
        assert not [l for l in git("ls-files", "-s").splitlines() if l.startswith("160000")]

    def test_no_gitlink_in_head(self):
        assert not [l for l in git("ls-tree", "-r", "HEAD").splitlines() if l.startswith("160000")]

    def test_no_gitmodules_and_no_nested_git(self):
        assert not os.path.exists(f"{REPO}/.gitmodules")
        assert not os.path.exists(f"{REPO}/cybconf/.git")
        assert not os.path.exists(f"{REPO}/cybconf/.github")

    def test_cybconf_key_files_tracked(self):
        files = set(git("ls-files", "cybconf").splitlines())
        for f in ["_config.yml", "Gemfile", "Gemfile.lock", "index.html"]:
            assert f"cybconf/{f}" in files

    def test_build_artifacts_not_tracked(self):
        bad = [f for f in git("ls-files").splitlines()
               if "cybconf/_site/" in f or ".jekyll-cache" in f or f.endswith(".zip")]
        assert bad == []


# Workflow YAML
class TestWorkflow:
    def test_workflow_valid(self):
        d = yaml.safe_load(open(f"{REPO}/.github/workflows/jekyll.yml"))
        assert set(d["jobs"]) == {"build", "deploy"}
        b = d["jobs"]["build"]
        assert b["defaults"]["run"]["working-directory"] == "cybconf"
        upload = [s for s in b["steps"] if "upload-pages-artifact" in s.get("uses", "")][0]
        assert upload["with"]["path"] == "cybconf/_site"
        assert d["jobs"]["deploy"]["needs"] == "build"
        assert git("ls-files", ".github/workflows/jekyll.yml").strip()


# Clean clone build (simulates CI checkout)
class TestCleanCloneBuild:
    def test_clone_and_build(self, tmp_path):
        dst = tmp_path / "clone"
        subprocess.run(["git", "clone", "-q", REPO, str(dst)], check=True)
        site = dst / "cybconf"
        assert (site / "Gemfile").exists()
        env = dict(os.environ, JEKYLL_ENV="production", BUNDLE_PATH="/tmp/clonevendor")
        r = subprocess.run(["bundle", "install", "--quiet"], cwd=site, env=env, capture_output=True, text=True)
        assert r.returncode == 0, r.stderr
        r = subprocess.run(["bundle", "exec", "jekyll", "build", "--baseurl", "/pp"],
                           cwd=site, env=env, capture_output=True, text=True)
        assert r.returncode == 0, r.stderr
        assert (site / "_site/index.html").exists()
        assert (site / "_site/call-for-papers/index.html").exists()
        shutil.rmtree(dst, ignore_errors=True)


# Live preview
class TestPreview:
    @pytest.mark.parametrize("path", ["/", "/call-for-papers/"])
    def test_pages_200(self, path):
        r = requests.get(FRONT_URL + path, timeout=20)
        assert r.status_code == 200
        assert "CYB" in r.text
