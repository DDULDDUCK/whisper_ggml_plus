#pragma once
#ifdef __cplusplus
extern "C" {
#endif
char *request(char *body);
void free_string(char *ptr);
#ifdef __cplusplus
}
#endif
