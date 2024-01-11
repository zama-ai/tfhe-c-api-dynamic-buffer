#[cfg(feature = "c_api")]
fn gen_c_api() {
    use std::env;
    use std::path::PathBuf;

    if std::env::var("_CBINDGEN_IS_RUNNING").is_ok() {
        return;
    }

    fn get_build_profile_name() -> String {
        // The profile name is always the 3rd last part of the path (with 1 based indexing).
        // e.g. /code/core/target/cli/build/my-build-info-9f91ba6f99d7a061/out
        let out_dir = std::env::var("OUT_DIR")
            .expect("OUT_DIR is not set, cannot determine build profile, aborting");
        out_dir
            .split(std::path::MAIN_SEPARATOR)
            .nth_back(3)
            .expect("Cannot determine build profile, aborting")
            .to_string()
    }

    /// Find the location of the `target/` directory. Note that this may be
    /// overridden by `cmake`, so we also need to check the `CARGO_TARGET_DIR`
    /// variable.
    fn target_dir() -> PathBuf {
        if let Ok(target) = env::var("CARGO_TARGET_DIR") {
            PathBuf::from(target)
        } else if option_env!("CARGO_PRIMARY_PACKAGE").is_some() {
            // If CARGO_PRIMARY_PACKAGE find the target from the manifest location
            PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap())
                .join(format!("target/{}", get_build_profile_name()))
        } else {
            // We are a dependency, yet another path to consider
            let out_dir = std::env::var("OUT_DIR")
                .expect("OUT_DIR is not set, cannot find place to store header, aborting");
            let out_dir_path = std::path::PathBuf::from(out_dir);

            // out_dir_path will be of the form
            // /some_path/project/target/release/build/tfhe-dynamic-buffer-3b8342b5a56a94ba/out
            // Need to go up three and then use the deps dir
            out_dir_path.ancestors().nth(3).unwrap().join("deps")
        }
    }

    extern crate cbindgen;
    let crate_dir: PathBuf = env::var("CARGO_MANIFEST_DIR").unwrap().into();
    let package_name = env::var("CARGO_PKG_NAME").unwrap();
    let output_file = target_dir().join(format!("{package_name}.h"));

    cbindgen::Builder::new()
        .with_crate(crate_dir.as_path())
        .with_config(cbindgen::Config::from_file(crate_dir.join("cbindgen.toml")).unwrap())
        .generate()
        .unwrap()
        .write_to_file(output_file);
}

fn main() {
    #[cfg(feature = "c_api")]
    gen_c_api()
}
